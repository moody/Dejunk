-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local UIParent, UISpecialFrames = UIParent, UISpecialFrames
local pairs, unpack = pairs, unpack

-- ChildFrame
local ChildFrame = DFL.ChildFrame

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL child frame.
function ChildFrame:Create()
  local childFrame = {}
  childFrame._isInitialized = false
  DFL:AddMixins(childFrame, self.Functions)
  return childFrame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = ChildFrame.Functions

  -- Initializes the frame.
  function Functions:Initialize()
    self._initial_show = true
    self._isInitialized = true
    self.Frame = DFL.Frame:Create()
    self:OnInitialize()
    self.Frame:Hide()
    -- Nop so the above code is only executed once
    self.Initialize = nop
    self.OnInitialize = nop
  end
  Functions.OnInitialize = nop

  -- Displays the frame.
  function Functions:Show()
    -- NOTE: When initially being shown, the frame will not be resized
    -- properly unless Resize() is called three times. I don't know why.
    if self._initial_show then
      self._initial_show = nil
      self.Frame:Resize()
      self.Frame:Resize()
    end

    self.Frame:Resize()
    self.Frame:Refresh()
    self.Frame:Show()
    self:OnShow()
  end
  Functions.OnShow = nop

  -- Hides the frame.
  function Functions:Hide()
    self.Frame:Hide()
    self:OnHide()
  end
  Functions.OnHide = nop

  -- Returns true if the frame is visible.
  function Functions:IsVisible()
    return self.Frame:IsVisible()
  end

  -- Toggles the frame.
  function Functions:Toggle()
    if not self.Frame:IsVisible() then
      self:Show()
    else
      self:Hide()
    end
  end

  -- Returns true if the frame is enabled.
  function Functions:IsEnabled() return self.Frame:IsEnabled() end
  -- Enables the frame.
  function Functions:Enable() self:SetEnabled(true) end
  -- Disables the frame.
  function Functions:Disable() self:SetEnabled(false) end
  -- Enables or disables the frame.
  function Functions:SetEnabled(enabled)
    if (self.Frame:IsEnabled() == enabled) then return end
    self.Frame:SetEnabled(enabled)
    self:OnSetEnabled(enabled)
  end
  Functions.OnSetEnabled = nop

  -- Refreshes the frame.
  function Functions:Refresh()
    self.Frame:Refresh()
    self:OnRefresh()
  end
  Functions.OnRefresh = nop

  -- Resizes the frame.
  function Functions:Resize()
    self.Frame:Resize()
    self:OnResize()
  end
  Functions.OnResize = nop

  -- Sets the parent of the frame.
  -- @param parent - the new parent
  function Functions:SetParent(parent)
    self.Frame:SetParent(parent)
  end

  -- Sets the point of the frame.
  -- @param point - the new point
  function Functions:SetPoint(...)
    self.Frame:SetPoint(...)
  end

  -- Sets the scale of the frame.
  -- @param scale - the new scale
  function Functions:SetScale(scale)
    self.Frame:SetScale(scale)
    self.Frame:Resize()
  end
end
