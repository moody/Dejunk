-- DejunkFrames: provides Dejunk frames with default functionality.

local AddonName, DJ = ...

local DejunkFrames = DJ.DejunkFrames -- See Modules.lua
local FrameFactory = DJ.FrameFactory

local DejunkFrameMixin = {
  Initialized = false,
  Enabled = false
}

-- Lifecycle hooks
function DejunkFrameMixin:OnInitialize() end
function DejunkFrameMixin:OnShow() end
function DejunkFrameMixin:OnHide() end
function DejunkFrameMixin:OnEnable() end
function DejunkFrameMixin:OnDisable() end
function DejunkFrameMixin:OnRefresh() end
function DejunkFrameMixin:OnResize() end
function DejunkFrameMixin:OnSetWidth(newWidth, oldWidth) end
function DejunkFrameMixin:OnSetHeight(newHeight, oldHeight) end

-- ============================================================================
--                          Frame Lifecycle Functions
-- ============================================================================

-- Initializes the frame.
function DejunkFrameMixin:Initialize()
  if self.Initialized then return end
  self.Initialized = true
  self.Enabled = true

  if not self.UI then
    self.UI = {}
  end

  self.Frame = FrameFactory:CreateFrame()

  self:OnInitialize()
end

-- Displays the frame.
function DejunkFrameMixin:Show()
  self:Refresh()
  self.Frame:Show()

  self:OnShow()
end

-- Hides the frame.
function DejunkFrameMixin:Hide()
  self.Frame:Hide()

  self:OnHide()
end

-- Returns true if the frame is visible.
function DejunkFrameMixin:IsVisible()
  return self.Initialized and self.Frame:IsVisible() or false
end

-- Toggles the frame.
function DejunkFrameMixin:Toggle()
  if not self.Frame:IsVisible() then
    self:Show()
  else
    self:Hide()
  end
end

-- Enables the frame.
function DejunkFrameMixin:Enable()
  FrameFactory:EnableUI(self.UI)
  self.Enabled = true

  self:OnEnable()
end

-- Disables the frame.
function DejunkFrameMixin:Disable()
  FrameFactory:DisableUI(self.UI)
  self.Enabled = false

  self:OnDisable()
end

-- Returns true if the frame is enabled.
function DejunkFrameMixin:IsEnabled()
  assert(self.Initialized)
  return self.Enabled
end

-- Refreshes the frame.
function DejunkFrameMixin:Refresh()
  self.Frame:Refresh()
  FrameFactory:RefreshUI(self.UI)

  self:OnRefresh()
end

-- Resizes the frame.
function DejunkFrameMixin:Resize()
  -- No base functionality required for now
  self:OnResize()
end

-- ============================================================================
--                           Getters and Setters
-- ============================================================================

-- Gets the width of the frame.
-- @return - the width of the frame
function DejunkFrameMixin:GetWidth()
  return self.Frame:GetWidth()
end

-- Sets the width of the frame.
-- @param width - the new width
function DejunkFrameMixin:SetWidth(newWidth)
  local oldWidth = self.Frame:GetWidth()
  self.Frame:SetWidth(newWidth)
  self:OnSetWidth(newWidth, oldWidth)
end

-- Gets the height of the frame.
-- @return - the height of the frame
function DejunkFrameMixin:GetHeight()
  return self.Frame:GetHeight()
end

-- Sets the height of the frame.
-- @param height - the new height
function DejunkFrameMixin:SetHeight(newHeight)
  local oldHeight = self.Frame:GetHeight()
  self.Frame:SetHeight(newHeight)
  self:OnSetHeight(newHeight, oldHeight)
end

-- Sets the parent of the frame.
-- @param parent - the new parent
function DejunkFrameMixin:SetParent(parent)
  self.Frame:SetParent(parent)
end

-- Sets the point of the frame.
-- @param point - the new point
function DejunkFrameMixin:SetPoint(...)
  -- self.Frame:ClearAllPoints()
  self.Frame:SetPoint(unpack(...))
end

-- Perform mixins
for i, frame in pairs(DejunkFrames) do
  for k, v in pairs(DejunkFrameMixin) do
    frame[k] = v
  end
end
