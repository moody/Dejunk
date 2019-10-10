local AddonName, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local GameTooltip = _G.GameTooltip
local NewTicker = _G.C_Timer.NewTicker
local Utils = Addon.UI.Utils

--[[
  Adds a basic AceGUI Button to a parent widget and returns it.

  options = {
    parent = widget,
    text = string,
    fullWidth = boolean,
    width = number,
    onClick = function,
    onEnter = function,
    onLeave = function
  }
]]
function Utils:Button(options)
  local button = AceGUI:Create("Button")
  button:SetText(options.text)
  button:SetFullWidth(options.fullWidth)
  if options.width then button:SetWidth(options.width) end
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
function Utils:CheckBox(options)
  local checkBox = AceGUI:Create("CheckBox")
  checkBox:SetValue(options.get())
  checkBox:SetLabel(options.label)

  checkBox:SetCallback("OnValueChanged", function(_, _, value)
    options.set(value)
  end)

  if options.tooltip then
    checkBox:SetCallback("OnEnter", function(self)
      GameTooltip:SetOwner(self.checkbg, "ANCHOR_TOP")
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
      value = number,
      min = number,
      max = number,
      step = number,
      onValueChanged = function
    }
  }
]]
function Utils:CheckBoxSlider(options)
  local group = Utils:SimpleGroup({
    parent = options.parent,
    fullWidth = true
  })

  local slider = AceGUI:Create("Slider")
  slider:SetSliderValues(
    options.slider.min,
    options.slider.max,
    options.slider.step
  )
  slider:SetLabel(options.slider.label)
  slider:SetValue(options.slider.value)
  slider:SetDisabled(not options.checkBox.get())
  slider:SetCallback("OnValueChanged", function(self, event, value)
    options.slider.onValueChanged(self, event, value)
    self.editbox:ClearFocus()
  end)

  Utils:CheckBox({
    parent = group,
    label = options.checkBox.label,
    tooltip = options.checkBox.tooltip,
    get = options.checkBox.get,
    set = function(value)
      options.checkBox.set(value)
      slider:SetDisabled(not value)
    end
  })

  group:AddChild(slider)
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
function Utils:Dropdown(options)
  local dropdown = AceGUI:Create("Dropdown")
  dropdown:SetLabel(options.label)
  dropdown:SetList(options.list)
  dropdown:SetValue(options.value)
  dropdown:SetCallback("OnValueChanged", options.onValueChanged)
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
function Utils:EditBox(options)
  local editBox = AceGUI:Create("EditBox")
  editBox:SetLabel(options.label)
  editBox:SetFullWidth(options.fullWidth)
  editBox:DisableButton(options.disableButton)
  editBox:SetCallback("OnEnterPressed", options.onEnterPressed)
  options.parent:AddChild(editBox)
  return editBox
end

-- Adds an AceGUI Heading to a parent widget and returns it.
function Utils:Heading(parent, text)
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
function Utils:Label(options)
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
function Utils:MultiLineEditBox(options)
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
  Adds an AceGUI InlineGroup to a parent widget and returns it.

  options = {
    parent = widget,
    title = string,
    fullWidth = boolean,
    layout = "Flow", -- "Flow" | "Fill" | "List"
  }
--]]
function Utils:InlineGroup(options)
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
function Utils:SimpleGroup(options)
  local simpleGroup = AceGUI:Create("SimpleGroup")
  simpleGroup:SetFullWidth(options.fullWidth)
  simpleGroup:SetFullHeight(options.fullHeight)
  simpleGroup:SetLayout(options.layout or "Flow")
  options.parent:AddChild(simpleGroup)
  return simpleGroup
end

--[[
  Add a Dejunk_ListFrame widget to a parent widget and returns it.

  options = {
    parent = widget,
    title = string,
    listName = string,
    listData = table
  }
]]
function Utils:ListFrame(options)
  local parent = self:InlineGroup({
    parent = options.parent,
    -- title = options.title,
    fullWidth = true
  })

  local listFrame = AceGUI:Create("Dejunk_ListFrame")
  listFrame:SetFullWidth(true)
  listFrame:SetListData(options.listName, options.listData)
  parent:AddChild(listFrame)

  return listFrame
end

--[[
  Sets up a ticker function for an AceGUI widget, which is cancelled during the
  `OnRelease` callback.

  Use this to dynamically update parts of the UI, such as text.

  Do not overwrite the `OnRelease` callback, or the ticker will never stop!
]]
function Utils:SetTicker(widget, func, delay)
  local ticker = NewTicker(delay or 1, function()
    if widget:IsVisible() then func(widget) end
  end)
  widget:SetCallback("OnRelease", function() ticker:Cancel() end)
end
