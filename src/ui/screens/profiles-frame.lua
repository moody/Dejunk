local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ProfilesFrame
local ProfilesFrame = Addon:GetModule("ProfilesFrame")

local Components = {}

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
    return frame
  end
})

-- ============================================================================
-- Title Components
-- ============================================================================

Components.TitleRow = Components.Root:AddRow({
  height = 32,
  paddingLeft = Widgets:Padding(),
  frameFactory = function(parent)
    local frame = Widgets:Frame({ parent = parent })
    frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
    return frame
  end
})

Components.TitleText = Components.TitleRow:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Yellow(L.PROFILES))
    return fontString
  end
})

Components.CloseButton = Components.TitleRow:AddChild({
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

-- TODO
Components.Content = Components.Root:AddChild({
  direction = "COLUMN",
  padding = Widgets:Padding(),
  gap = Widgets:Padding(0.5),
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
