local _, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Clamp = _G.Clamp
local GameTooltip = _G.GameTooltip
local Widgets = Addon.UI.Widgets

--[[
  Adds a basic AceGUI Button to a parent widget and returns it.

  options = {
    parent = widget,
    text = string,
    fullWidth = boolean,
    width = number,
    height = number,
    onClick = function,
    onEnter = function,
    onLeave = function
  }
]]
function Widgets:Button(options)
  local button = AceGUI:Create("Button")
  button:SetText(options.text)
  button:SetFullWidth(options.fullWidth)
  if options.width then button:SetWidth(options.width) end
  if options.height then button:SetHeight(options.height) end
  button:SetCallback("OnClick", options.onClick)
  button:SetCallback("OnEnter", options.onEnter)
  button:SetCallback("OnLeave", options.onLeave)
  options.parent:AddChild(button)
  return button
end

--[[
  Adds a basic AceGUI CheckBox to a parent widget and returns it.

  options = {
    parent = widget,
    label = string,
    tooltip = string,
    get = function() -> boolean,
    set = function(value)
  }
]]
function Widgets:CheckBox(options)
  local checkBox = AceGUI:Create("CheckBox")
  checkBox:SetValue(options.get())
  checkBox:SetLabel(options.label)

  checkBox:SetCallback("OnValueChanged", function(_, _, value)
    options.set(value)
  end)

  if options.tooltip then
    checkBox:SetCallback("OnEnter", function(this)
      GameTooltip:SetOwner(this.checkbg, "ANCHOR_TOP")
      GameTooltip:SetText(options.label, 1.0, 0.82, 0)
      GameTooltip:AddLine(options.tooltip, 1, 1, 1, true)
      GameTooltip:Show()
    end)

    checkBox:SetCallback("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  options.parent:AddChild(checkBox)
  return checkBox
end

--[[
  Adds a SimpleGroup with a CheckBox and Slider to a parent widget and returns
  it.

  options = {
    parent = widget,
    checkBox = {
      label = string,
      tooltip = string,
      get = function() -> boolean,
      set = function(value)
    },
    slider = {
      label = string,
      tooltip = string,
      value = number,
      min = number,
      max = number,
      step = number,
      onValueChanged = function(this, event, value) -> nil
    }
  }
]]
function Widgets:CheckBoxSlider(options)
  local group = self:SimpleGroup({
    parent = options.parent,
    fullWidth = true
  })

  local slider

  self:CheckBox({
    parent = group,
    label = options.checkBox.label,
    tooltip = options.checkBox.tooltip,
    get = options.checkBox.get,
    set = function(value)
      options.checkBox.set(value)
      slider:SetDisabled(not value)
    end
  })

  slider = self:Slider({
    parent = group,
    label = options.slider.label,
    tooltip = options.slider.tooltip,
    value = options.slider.value,
    min = options.slider.min,
    max = options.slider.max,
    step = options.slider.step,
    onValueChanged = options.slider.onValueChanged
  })
  slider:SetDisabled(not options.checkBox.get())

  return group
end

--[[
  Adds a SimpleGroup with a CheckBox and min-max value Sliders to a parent
  widget and returns it.

  options = {
    parent = widget,
    checkBox = {
      label = string,
      tooltip = string,
      get = function() -> boolean,
      set = function(value)
    },
    minSlider = {
      label = string,
      tooltip = string,
      value = number,
      min = number,
      max = number,
      step = number,
      onValueChanged = function(this, event, value) -> nil
    },
    maxSlider = {
      label = string,
      tooltip = string,
      value = number,
      min = number,
      max = number,
      step = number,
      onValueChanged = function(this, event, value) -> nil
    }
  }
]]
function Widgets:CheckBoxSliderRange(options)
  local group = self:SimpleGroup({
    parent = options.parent,
    fullWidth = true,
  })

  -- Private data table.
  local _t = {}

  -- Updates and constrains both sliders.
  local _onValueChanged = (function()
    local function constrain(slider, min, max)
      local value = Clamp(slider:GetValue(), min, max)
      slider:SetSliderValues(min, max, slider.step)
      slider:SetValue(value)
      return value
    end

    return function(this, event)
      local min = constrain(_t.minSlider, options.minSlider.min, _t.maxSlider:GetValue())
      local max = constrain(_t.maxSlider, _t.minSlider:GetValue(), options.maxSlider.max)
      options.minSlider.onValueChanged(this, event, min)
      options.maxSlider.onValueChanged(this, event, max)
    end
  end)()

  -- Check box.
  self:CheckBox({
    parent = group,
    label = options.checkBox.label,
    tooltip = options.checkBox.tooltip,
    get = options.checkBox.get,
    set = function(value)
      options.checkBox.set(value)
      _t.minSlider:SetDisabled(not value)
      _t.maxSlider:SetDisabled(not value)
    end
  })

  -- Slider group.
  local sliderGroup = self:SimpleGroup({
    parent = group,
    fullWidth = true,
  })

  -- Minimum value slider.
  _t.minSlider = self:Slider({
    parent = sliderGroup,
    label = options.minSlider.label,
    tooltip = options.minSlider.tooltip,
    value = options.minSlider.value,
    min = options.minSlider.min,
    max = options.minSlider.max,
    step = options.minSlider.step,
    onValueChanged = _onValueChanged
  })
  _t.minSlider:SetDisabled(not options.checkBox.get())

  -- Maximum value slider.
  _t.maxSlider = self:Slider({
    parent = sliderGroup,
    label = options.maxSlider.label,
    tooltip = options.maxSlider.tooltip,
    value = options.maxSlider.value,
    min = options.maxSlider.min,
    max = options.maxSlider.max,
    step = options.maxSlider.step,
    onValueChanged = _onValueChanged
  })
  _t.maxSlider:SetDisabled(not options.checkBox.get())

  return group
end

--[[
  Adds a basic AceGUI Dropdown to a parent widget and returns it.

  options = {
    parent = widget,
    label = string,
    list = table,
    value = string,
    onValueChanged = function
  }
]]
function Widgets:Dropdown(options)
  local dropdown = AceGUI:Create("Dropdown")
  dropdown:SetLabel(options.label)
  dropdown:SetList(options.list)
  dropdown:SetValue(options.value)
  dropdown:SetCallback("OnValueChanged", options.onValueChanged)

  if options.tooltip then
    dropdown:SetCallback("OnEnter", function(this)
      GameTooltip:SetOwner(this.label, "ANCHOR_TOPLEFT")
      GameTooltip:SetText(options.label, 1.0, 0.82, 0)
      GameTooltip:AddLine(options.tooltip, 1, 1, 1, true)
      GameTooltip:Show()
    end)

    dropdown:SetCallback("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  options.parent:AddChild(dropdown)
  return dropdown
end

--[[
  Adds a basic AceGUI EditBox to a parent widget and returns it.

  options = {
    parent = widget,
    label = string,
    fullWidth = boolean,
    disableButton = boolean,
    onEnterPressed = function
  }
]]
function Widgets:EditBox(options)
  local editBox = AceGUI:Create("EditBox")
  editBox:SetLabel(options.label)
  editBox:SetFullWidth(options.fullWidth)
  editBox:DisableButton(options.disableButton)
  editBox:SetCallback("OnEnterPressed", options.onEnterPressed)
  options.parent:AddChild(editBox)
  return editBox
end

-- Adds an AceGUI Heading to a parent widget and returns it.
function Widgets:Heading(parent, text)
  local heading = AceGUI:Create("Heading")
  heading:SetText(text)
  heading:SetFullWidth(true)
  parent:AddChild(heading)
  return heading
end

--[[
  Adds a basic AceGUI Label to a parent widget and returns it.

  options = {
    parent = widget,
    text = string,
    fullWidth = boolean,
    color = table
  }
]]
function Widgets:Label(options)
  local label = AceGUI:Create("Label")
  label:SetText(options.text)
  label:SetFullWidth(options.fullWidth)

  if options.color then
    label:SetColor(options.color.r, options.color.g, options.color.b)
  end

  options.parent:AddChild(label)
  return label
end

--[[
  Adds a basic AceGUI MultiLineEditBox to a parent widget and returns it.

  options = {
    parent = widget,
    label = string,
    text = string,
    fullWidth = boolean,
    numLines = number
  }
]]
function Widgets:MultiLineEditBox(options)
  local editBox = AceGUI:Create("MultiLineEditBox")
  editBox:SetLabel(options.label)
  editBox:SetText(options.text or "")
  editBox:SetFullWidth(options.fullWidth)
  editBox:SetNumLines(options.numLines or 10)
  editBox:DisableButton(true)
  options.parent:AddChild(editBox)
  return editBox
end

--[[
  Adds a Slider to a parent widget and returns it.

  options = {
    parent = widget,
    label = string,
    tooltip = string,
    value = number,
    min = number,
    max = number,
    step = number,
    onValueChanged = function(this, event, value) -> nil
  }
]]
function Widgets:Slider(options)
  local slider = AceGUI:Create("Slider")
  slider:SetSliderValues(
    options.min,
    options.max,
    options.step
  )
  slider:SetLabel(options.label)
  slider:SetValue(options.value)
  slider:SetCallback("OnValueChanged", function(this, event, value)
    options.onValueChanged(this, event, value)
    this.editbox:ClearFocus()
  end)

  if options.tooltip then
    slider:SetCallback("OnEnter", function(this)
      GameTooltip:SetOwner(this.label, "ANCHOR_TOP")
      GameTooltip:SetText(options.label, 1.0, 0.82, 0)
      GameTooltip:AddLine(options.tooltip, 1, 1, 1, true)
      GameTooltip:Show()
    end)

    slider:SetCallback("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  options.parent:AddChild(slider)
  return slider
end

--[[
  Adds an AceGUI InlineGroup to a parent widget and returns it.

  options = {
    parent = widget,
    title = string,
    fullWidth = boolean,
    layout = "Flow", -- "Flow" | "Fill" | "List"
  }
--]]
function Widgets:InlineGroup(options)
  local inlineGroup = AceGUI:Create("InlineGroup")
  inlineGroup:SetTitle(options.title)
  inlineGroup:SetFullWidth(options.fullWidth)
  inlineGroup:SetLayout(options.layout or "Flow")
  options.parent:AddChild(inlineGroup)
  return inlineGroup
end

--[[
  Adds an AceGUI SimpleGroup to a parent widget and returns it.

  options = {
    parent = widget,
    fullWidth = boolean,
    fullHeight = boolean,
    layout = "Flow", -- "Flow" | "Fill" | "List"
  }
--]]
function Widgets:SimpleGroup(options)
  local simpleGroup = AceGUI:Create("SimpleGroup")
  simpleGroup:SetFullWidth(options.fullWidth)
  simpleGroup:SetFullHeight(options.fullHeight)
  simpleGroup:SetLayout(options.layout or "Flow")
  options.parent:AddChild(simpleGroup)
  return simpleGroup
end

--[[
  Adds a Dejunk_ListFrame widget to a parent widget and returns it.

  options = {
    parent = widget,
    title = string,
    list = table
  }
]]
function Widgets:ListFrame(options)
  local parent = self:InlineGroup({
    parent = options.parent,
    -- title = options.title,
    fullWidth = true
  })

  local listFrame = AceGUI:Create("Dejunk_ListFrame")
  listFrame:SetFullWidth(true)
  listFrame:SetList(options.list)
  parent:AddChild(listFrame)

  return listFrame
end

--[[
  Adds a Dejunk_ItemFrame widget to a parent widget and returns it.

  options = {
    parent = widget,
    title = string,
    data = {
      lists = table,
      items = table,
      handleItem = function
    }
  }
]]
function Widgets:ItemFrame(options)
  local parent = self:InlineGroup({
    parent = options.parent,
    title = options.title,
    fullWidth = true
  })

  local itemFrame = AceGUI:Create("Dejunk_ItemFrame")
  itemFrame:SetFullWidth(true)

  if options.data then
    itemFrame:SetData(options.data)
  end

  parent:AddChild(itemFrame)
  return itemFrame
end
