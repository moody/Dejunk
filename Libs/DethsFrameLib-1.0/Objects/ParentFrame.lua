-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local UIParent, UISpecialFrames = UIParent, UISpecialFrames
local pairs, unpack = pairs, unpack

-- ParentFrame
local ParentFrame = DFL.ParentFrame
ParentFrame.FrameFunctions = {}
ParentFrame.FrameScripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL parent frame.
function ParentFrame:Create()
  local parentFrame = DFL.ChildFrame:Create()
  DFL:AddMixins(parentFrame, self.Functions)
  return parentFrame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = ParentFrame.Functions

  -- Initializes the frame.
  function Functions:Initialize()
    self._initial_show = true
    self._isInitialized = true

    -- Create underlying frame
    local frame = DFL.Frame:Create()
    self.Frame = frame
    frame._parent_frame = self
    -- Center
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    -- Make draggable
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    -- Allow WoW to handle hiding frame when necessary
    UISpecialFrames[#UISpecialFrames+1] = frame:GetName()
    
    DFL:AddMixins(frame, ParentFrame.FrameFunctions)
    DFL:AddScripts(frame, ParentFrame.FrameScripts)
    
    frame:SetDirection(DFL.Directions.DOWN)
    frame:SetMinWidth(10)
    frame:SetMinHeight(10)
    frame:SetColors()
    frame:Refresh()
    
    self:OnInitialize()
    frame:Hide()
    
    -- Nop so the above code is only executed once
    self.Initialize = nop
    self.OnInitialize = nop
  end
  Functions.OnInitialize = nop

  -- Returns the title ChildFrame of the ParentFrame.
  function Functions:GetTitle()
    return self._title
  end

  -- Sets the title ChildFrame of the ParentFrame.
  function Functions:SetTitle(title)
    if self._title then self.Frame:Remove(self._title.Frame) end

    if title then
      assert(DFL:IsType(title, DFL.ChildFrame:GetType()), "title must be a ChildFrame")
      title:Initialize()
      title:Show()
      title:SetEnabled(self:IsEnabled())
      self.Frame:Add(title.Frame, 1)
    end

    self._title = title
    self.Frame:Resize()
  end

  -- Returns the content ChildFrame of the ParentFrame.
  function Functions:GetContent()
    return self._content
  end

  -- Sets the content ChildFrame of the ParentFrame.
  function Functions:SetContent(content)
    if self._content then self.Frame:Remove(self._content.Frame) end

    if content then
      assert(DFL:IsType(content, DFL.ChildFrame:GetType()), "content must be a ChildFrame")
      content:Initialize()
      content:Show()
      content:SetEnabled(self:IsEnabled())
      self.Frame:Add(content.Frame)
    end

    self._content = content
    self.Frame:Resize()
  end

  -- Queues the ParentFrame's frame for resizing.
  function Functions:QueueResize()
    self.Frame._resize_queued = true
  end
end

-- ============================================================================
-- FrameFunctions
-- ============================================================================

do
  local Functions = ParentFrame.FrameFunctions

  -- Returns the ParentFrame the frame belongs to.
  function Functions:GetParent()
    return self._parent_frame
  end

  function Functions:SetColors(color, borderColor)
    DFL.Frame.Functions.SetColors(self, color)
    self._borderColor = borderColor or self._borderColor or DFL.Colors.Area
  end

  function Functions:Refresh()
    DFL.Frame.Functions.Refresh(self)
    DFL:AddBorder(self, unpack(self._borderColor))
  end
end

-- ============================================================================
-- FrameScripts
-- ============================================================================

do
  local Scripts = ParentFrame.FrameScripts
  
  function Scripts:OnDragStart() self:StartMoving() end
  function Scripts:OnDragStop() self:StopMovingOrSizing() end

  function Scripts:OnUpdate(elapsed)
    if self._resize_queued then
      self._resize_queued = false
      self:Resize()
    end
    
    if self._parent_frame.OnUpdate then
      self._parent_frame:OnUpdate(elapsed)
    end
  end
end
