-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local assert, floor, pairs, ipairs, max, nop, tonumber, type, unpack =
      assert, floor, pairs, ipairs, max, nop, tonumber, type, unpack

-- FauxScrollFrame
local FauxScrollFrame = DFL.FauxScrollFrame
FauxScrollFrame.Scripts = {}
FauxScrollFrame.SliderScripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL faux scroll frame.
-- @param parent - the parent frame
-- @param data - a table of data for faux objects. Data items are retrieved by
-- index and passed to objects using an object's SetData(data) function.
-- @param objFunc - the function called to create faux scroll objects. These
-- objects must implement a SetData(data) function.
-- @param numObjects - the number of objects to create
function FauxScrollFrame:Create(parent, data, objFunc, numObjects)
  assert(type(data) == "table", "data must be a table")
  assert(type(objFunc) == "function", "objFunc must be a function")
  numObjects = tonumber(numObjects) or 0
  assert(numObjects > 0, "numObjects must be > 0")
  
  local frame = DFL.Frame:Create(parent)
  frame:SetSpacing(DFL:Padding(0.25))
  frame._data = data
  frame._offset = 0

  -- objFrame, holds objects created with objFunc
  local objFrame = DFL.Frame:Create(frame,
    DFL.Alignments.TOPLEFT, DFL.Directions.DOWN)
  objFrame:SetLayout(DFL.Layouts.FLOW_EQUAL)
  objFrame:SetPadding(DFL:Padding(0.5))
  objFrame:SetSpacing(DFL:Padding(0.5))

  -- Add required number of objects
  for i = 1, numObjects do
    local obj = objFunc(objFrame)
    if not (type(obj.SetData) == "function") then
      error("FauxScrollFrame objects must have a SetData function")
    end
    objFrame:Add(obj)
  end

  frame._objFrame = objFrame
  frame:Add(objFrame)

  -- slider
  local slider = DFL.Slider:Create(frame)
  slider.SetEnabled = nop
  slider:SetValueStep(1)
  frame._slider = slider
  frame:Add(slider)
  
  DFL:AddMixins(frame, self.Functions)
  DFL:AddScripts(frame, self.Scripts)
  DFL:AddScripts(slider, self.SliderScripts)

  frame:SetColors()
  frame:Refresh()

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = FauxScrollFrame.Functions

  function Functions:SetData(data)
    assert(type(data) == "table", "data must be a table")
    self._data = data
    self._offset = 0
  end

  function Functions:SetColors(color, sliderColors, ...)
    self._objFrame:SetColors(color or DFL.Colors.Area)
    if sliderColors then self._slider:SetColors(unpack(sliderColors)) end
    if (#{...} > 0) then
      for _, object in pairs(self._objFrame:GetChildren()) do
        if object.SetColors then object:SetColors(...) end
      end
    end
  end

  function Functions:Resize()
    DFL.Frame.Functions.Resize(self)
    self._slider:SetHeight(self:GetHeight())
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = FauxScrollFrame.Scripts

  function Scripts:OnUpdate(elapsed)
    local objects = self._objFrame:GetChildren()

    -- Update objects
    for i, object in ipairs(objects) do
      local index = (i + self._offset)
      local data = self._data[index]

      if data then
        object:Show()
        object:SetData(data)
      else
        object:Hide()
      end
    end

    -- Update slider values, show slider if max value is > 0
    local maxVal = max((#self._data - #objects), 0)
    self._slider:SetMinMaxValues(0, maxVal)
    if (maxVal > 0) then self:Add(self._slider) else self:Remove(self._slider) end

    if self.OnUpdate then self:OnUpdate(elapsed) end
  end

  function Scripts:OnMouseWheel(delta)
    self._slider:SetValue(self._slider:GetValue() - delta)
  end
end

-- ============================================================================
-- SliderScripts
-- ============================================================================

do
  local SliderScripts = FauxScrollFrame.SliderScripts

  function SliderScripts:OnValueChanged()
    self:GetParent()._offset = floor(self:GetValue() + 0.5)
  end
end
