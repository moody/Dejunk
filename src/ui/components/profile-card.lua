local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ProfileCardComponentOptions
--- @field isActive fun(profile: ProfileState): boolean Whether the profile is the active one.
--- @field isProtected fun(profile: ProfileState): boolean Whether the profile cannot be renamed or deleted.
--- @field onActivate fun(profile: ProfileState) Called when the card is clicked.
--- @field onRename fun(profile: ProfileState)
--- @field onDuplicate fun(profile: ProfileState)
--- @field onReset fun(profile: ProfileState)
--- @field onDelete fun(profile: ProfileState)
--- @field onUpdateTooltip? fun(profile: ProfileState, tooltip: Tooltip) Shown while hovering the card.

-- =============================================================================
-- ComponentFactory - ProfileCard
-- =============================================================================

--- Creates a card for a profile, with rename, duplicate, reset, and delete buttons and a strip on the left edge while
--- it is active. Hidden until it has a profile.
--- @param options ProfileCardComponentOptions
--- @return ProfileCardComponent root
function ComponentFactory:ProfileCard(options)
  local frame ---@type FrameWidget?
  local accent ---@type Texture?
  local profile ---@type ProfileState?
  local isActive = false

  --- Values last shown, to skip a profile that has not changed.
  local shown = {}

  --- Brightens the card while hovered, if it has a profile.
  local function refreshBackdrop()
    if not frame then return end

    local isHighlighted = profile and frame:GetEventValue("HOVERED")
    frame:SetBackdropColor(Colors.White:GetRGBA(isHighlighted and 0.06 or 0.03))
  end

  --- Shows the strip while the profile is active.
  local function refreshAccent()
    if accent then accent:SetColorTexture(Colors.Blue:GetRGBA(isActive and 1 or 0)) end
  end

  --- @class ProfileCardComponent : WaffleFlexComponent<FrameWidget>
  local root = Addon.Waffle:Flex({
    align = "CENTER",
    paddingLeft = ComponentFactory.CARD_ACCENT_WIDTH,
    visibility = "INVISIBLE",

    --- @param parent Frame
    frameFactory = function(parent)
      frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        tooltipAnchor = "ANCHOR_RIGHT",

        --- @param tooltip Tooltip
        onUpdateTooltip = function(_, tooltip)
          if profile and options.onUpdateTooltip then
            options.onUpdateTooltip(profile, tooltip)
          else
            tooltip:Hide()
          end
        end
      })
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:OnEvent("HOVERED", refreshBackdrop)
      refreshBackdrop()

      frame:SetScript("OnClick", function()
        if profile then options.onActivate(profile) end
      end)

      accent = frame:CreateTexture("$parent_Accent", "ARTWORK")
      accent:SetWidth(ComponentFactory.CARD_ACCENT_WIDTH)
      accent:SetPoint("TOPLEFT")
      accent:SetPoint("BOTTOMLEFT")
      refreshAccent()

      return frame
    end
  })

  -- Content, beside the accent strip.
  local content = root:AddRow({
    height = "AUTO",
    align = "CENTER",
    padding = Widgets:Padding(0.5),
    paddingLeft = Widgets:Padding(),
    paddingRight = Widgets:Padding()
  })

  -- Name.
  local nameText = content:AttachComponent(ComponentFactory:Text({
    wordWrap = false,
    truncationTooltip = false
  }))

  -- Buttons, the full height of the card.
  local renameButton = root:AttachComponent(ComponentFactory:IconButton({
    icon = Addon:GetAsset("pencil-icon"),
    highlightColor = Colors.Blue,
    width = ComponentFactory.CARD_BUTTON_WIDTH,
    onClick = function() if profile then options.onRename(profile) end end,
    onUpdateTooltip = function(_, tooltip) tooltip:SetText(L.RENAME) end
  }))

  root:AttachComponent(ComponentFactory:IconButton({
    icon = Addon:GetAsset("copy-icon"),
    highlightColor = Colors.Green,
    width = ComponentFactory.CARD_BUTTON_WIDTH,
    onClick = function() if profile then options.onDuplicate(profile) end end,
    onUpdateTooltip = function(_, tooltip) tooltip:SetText(L.DUPLICATE) end
  }))

  root:AttachComponent(ComponentFactory:IconButton({
    icon = Addon:GetAsset("reset-icon"),
    highlightColor = Colors.Yellow,
    width = ComponentFactory.CARD_BUTTON_WIDTH,
    onClick = function() if profile then options.onReset(profile) end end,
    onUpdateTooltip = function(_, tooltip) tooltip:SetText(L.RESET) end
  }))

  local deleteButton = root:AttachComponent(ComponentFactory:IconButton({
    icon = Addon:GetAsset("trash-icon"),
    highlightColor = Colors.Red,
    width = ComponentFactory.CARD_BUTTON_WIDTH,
    onClick = function() if profile then options.onDelete(profile) end end,
    onUpdateTooltip = function(_, tooltip) tooltip:SetText(L.DELETE) end
  }))

  -- Rename and delete are dimmed and disabled for a protected profile.
  for _, button in ipairs({ renameButton, deleteButton }) do
    button:WhenFrameReady(function(buttonFrame)
      buttonFrame:OnEvent("ENABLED", function(isEnabled)
        buttonFrame:SetAlpha(isEnabled and 1 or 0.3)
      end)
    end)
  end

  --- Shows the profile, or hides the card if it has none. Call it again to refresh the profile.
  --- @param newProfile? ProfileState
  function root:SetProfile(newProfile)
    local hadProfile = profile ~= nil
    profile = newProfile

    if not newProfile then
      shown.id = nil
      root:SetVisibility("INVISIBLE")
      return
    end

    root:SetVisibility("VISIBLE")
    if not hadProfile then refreshBackdrop() end

    local newIsActive = options.isActive(newProfile)
    local isProtected = options.isProtected(newProfile)

    local isChanged = (
      newProfile.id ~= shown.id or
      newProfile.name ~= shown.name or
      newIsActive ~= shown.isActive or
      isProtected ~= shown.isProtected
    )
    if not isChanged then return end

    shown.id = newProfile.id
    shown.name = newProfile.name
    shown.isActive = newIsActive
    shown.isProtected = isProtected

    isActive = newIsActive
    refreshAccent()

    nameText:SetText((isActive and Colors.White or Colors.Grey)(newProfile.name))

    for _, button in ipairs({ renameButton, deleteButton }) do
      button:WhenFrameReady(function(buttonFrame)
        buttonFrame:FireEvent("ENABLED", not isProtected)
      end)
    end

    -- A card under the mouse gets no new enter event when its profile changes, so refresh its tooltip.
    if frame and frame:IsVisible() and frame:IsMouseOver() then frame:UpdateTooltip() end
  end

  return root
end
