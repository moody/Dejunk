local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local DefaultStates = Addon:GetModule("DefaultStates")
local L = Addon:GetModule("Locale")
local Popup = Addon:GetModule("Popup")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ProfilesFrame
local ProfilesFrame = Addon:GetModule("ProfilesFrame")

local NUM_PROFILE_PANEL_BUTTONS = 7

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- @param button ProfilePanelButton
--- @return boolean
local function isDefaultProfileSelected(button)
  return button.profile.id == DefaultStates.DEFAULT_PROFILE_ID
end

--- @param button ProfilePanelButton
--- @return boolean
local function isProfileButtonSelected(button)
  return button.profile ~= nil and button.profile.id == StateManager:GetProfileState().id
end

-- Refresh components based on profile data.
local function refresh()
  local profiles = StateManager:GetAllProfiles()

  -- Update active profile text.
  Components.ProfilesPanelActiveProfileText
      :GetFrame()
      :SetText(L.ACTIVE_PROFILE .. " " .. Colors.Yellow(StateManager:GetProfileState().name))

  --- @type SliderWidget
  local slider = Components.ProfilesPanelSlider:GetFrame()
  local offset = math.floor(slider:GetValue() + 0.5)

  -- Update buttons.
  for i, button in ipairs(Components.ProfilesPanelButtons) do
    local profile = profiles[i + offset]
    --- @type ProfilePanelButton
    local f = button:GetFrame()
    f:SetProfile(profile)
    if profile ~= nil then f:Show() else f:Hide() end
  end

  -- Update slider.
  local maxScroll = math.max(#profiles - NUM_PROFILE_PANEL_BUTTONS, 0)
  if slider then slider:SetMinMaxValues(0, maxScroll) end
  Components.ProfilesPanelSlider:SetHidden(maxScroll <= 0)

  -- Layout.
  Components.Root:Layout()
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = Addon.Waffle:Flex({
  width = 325,
  height = 375,
  direction = "COLUMN",
  hidden = true,

  defaultFrameFactory = function(parent)
    return CreateFrame("Frame")
  end,

  frameFactory = function(parent)
    local frame = Widgets:Frame({
      name = ADDON_NAME .. "_ProfilesFrame",
      enableClickHandling = true,
      enableDragging = true
    })
    frame:SetFrameLevel(10)

    frame:SetClickHandler("RightButton", "SHIFT", function()
      StateManager:Dispatch(ActionCreators.Global.points.profilesFrame.reset())
    end)

    Widgets:ConfigureForPointSync(frame, "ProfilesFrame")

    table.insert(UISpecialFrames, frame:GetName())

    frame:Hide()
    frame:HookScript("OnHide", function()
      Components.Root:SetHidden(true)
    end)

    -- Bind refresh() to the root frame.
    TickerManager:NewTicker(1 / 30, refresh):BindFrame(frame)

    return frame
  end
})

-- ============================================================================
-- Title Components
-- ============================================================================

local titleRow = Components.Root:AddRow({
  height = 32,
  paddingLeft = Widgets:Padding(),
  frameFactory = function(parent)
    local frame = Widgets:Frame({ parent = parent })
    frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
    return frame
  end
})

-- Title text.
titleRow:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Yellow(L.PROFILES))
    return fontString
  end
})

-- Close button.
titleRow:AddChild({
  width = 46,
  frameFactory = function(parent)
    return Widgets:TitleFrameIconButton({
      name = "$parent_CloseButton",
      texture = Addon:GetAsset("x-icon"),
      textureSize = 14,
      highlightColor = Colors.Red,
      onClick = function() ProfilesFrame:Hide() end
    })
  end
})

-- ============================================================================
-- Content Components
-- ============================================================================

local contentColumn = Components.Root:AddChild({
  direction = "COLUMN",
  padding = Widgets:Padding(),
  gap = Widgets:Padding(0.5),
})

-- Container for the profiles header and content components.
local profilesPanel = contentColumn:AddColumn({
  frameFactory = function(parent)
    local frame = Widgets:Frame({ parent = parent, name = "$parent_ProfilesPanel" })

    -- Scroll on mouse wheel.
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
      local slider = Components.ProfilesPanelSlider:GetFrame()
      if slider then slider:SetValue(slider:GetValue() - delta) end
    end)

    return frame
  end
})

-- Active profile text.
Components.ProfilesPanelActiveProfileText = profilesPanel:AddRow({
  height = 28,
  padding = Widgets:Padding(),
  frameFactory = function(parent)
    local frame = Widgets:Frame({
      parent = parent,
      onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(Components.ProfilesPanelActiveProfileText:GetFrame():GetText())
      end
    })
    frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
    return frame
  end
}):AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_ActiveProfileText", "ARTWORK", "GameFontNormal")
    fontString:SetTextColor(1, 1, 1)
    fontString:SetJustifyH("CENTER")
    fontString:SetWordWrap(false)
    fontString:SetText("")
    return fontString
  end
})

local profilesPanelContent = profilesPanel:AddRow({
  padding = Widgets:Padding(),
  gap = Widgets:Padding(),
})

-- Container for the profile buttons.
local profilesPanelButtonColumn = profilesPanelContent:AddColumn({ gap = Widgets:Padding() })

Components.ProfilesPanelSlider = profilesPanelContent:AddChild({
  width = 12,
  frameFactory = function(parent)
    return Widgets:Slider({ name = "$parent_Slider", parent = parent })
  end
})

Components.ProfilesPanelButtons = {}
for i = 1, NUM_PROFILE_PANEL_BUTTONS do
  Components.ProfilesPanelButtons[i] = profilesPanelButtonColumn:AddChild({
    frameFactory = function()
      --- @class ProfilePanelButton : OptionButtonWidget
      --- @field profile? ProfileState
      local button
      button = Widgets:OptionButton({
        labelText = "",
        get = function() return isProfileButtonSelected(button) end,
        set = function() end,
        enableClickHandling = true,
        onUpdateTooltip = function(_, tooltip)
          tooltip:SetText(button.profile.name)
          if not isProfileButtonSelected(button) then
            tooltip:AddDoubleLine(L.LEFT_CLICK, L.ACTIVATE)
          end
          if not isDefaultProfileSelected(button) then
            tooltip:AddDoubleLine(L.RIGHT_CLICK, L.RENAME)
            tooltip:AddDoubleLine(Addon:Concat("+", L.ALT_KEY, L.RIGHT_CLICK), Colors.Red(L.DELETE))
          end
        end
      })

      -- Override OptionButton's default click/alpha handling.
      button:SetScript("OnClick", nil)
      button:SetScript("OnUpdate", nil)

      -- Left-click: activate.
      button:SetClickHandler("LeftButton", "NONE", function()
        if button.profile.id ~= StateManager:GetProfileState().id then
          StateManager:Dispatch(ActionCreators.Profiles.assignProfile({
            characterKey = Addon:GetCharacterKey(),
            profileId = button.profile.id
          }))
        end
      end)

      -- Right-click: rename.
      button:SetClickHandler("RightButton", "NONE", function()
        if isDefaultProfileSelected(button) then return end
        Popup:GetString({
          initialValue = button.profile.name,
          text = L.RENAME_PROFILE_POPUP_HELP:format(Colors.Yellow(button.profile.name)),
          onAccept = function(self, value)
            if value ~= button.profile.name then
              StateManager:Dispatch(ActionCreators.Profiles.renameProfile({
                profileId = button.profile.id,
                profileName = value
              }))
            end
          end
        })
      end)

      -- Alt+Right-click: delete.
      button:SetClickHandler("RightButton", "ALT", function()
        if isDefaultProfileSelected(button) then return end
        Popup:Confirm({
          text = L.DELETE_PROFILE_POPUP_HELP:format(Colors.Yellow(button.profile.name)),
          onAccept = function()
            StateManager:Dispatch(ActionCreators.Profiles.deleteProfile({
              profileId = button.profile.id
            }))
          end
        })
      end)

      --- @param profile? ProfileState
      function button:SetProfile(profile)
        self.profile = profile
        self.label:SetText(Colors.White(profile and profile.name or ""))
        button:SetAlpha(isProfileButtonSelected(button) and 1 or 0.5)
      end

      return button
    end
  })
end

-- New profile button.
contentColumn:AddChild({
  maxHeight = 30,
  justify = "END",
  frameFactory = function()
    return Widgets:Button({
      name = "$parent_NewProfileButton",
      labelText = L.NEW_PROFILE,
      labelColor = Colors.Yellow,
      onClick = function()
        Popup:GetString({
          text = L.NEW_PROFILE_POPUP_HELP,
          onAccept = function(self, value)
            StateManager:CreateNewProfile(value)
          end
        })
      end
    })
  end
})

-- ============================================================================
-- ProfilesFrame
-- ============================================================================

function ProfilesFrame:Show()
  Components.Root:SetHidden(false)
  Components.Root:Layout()
end

function ProfilesFrame:Hide()
  Components.Root:SetHidden(true)
  Components.Root:Layout()
end

function ProfilesFrame:Toggle()
  if Components.Root:GetHidden() then
    self:Show()
  else
    self:Hide()
  end
end
