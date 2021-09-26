local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local Destroy = Addon.UI.Groups.Destroy
local L = Addon.Libs.L
local Widgets = Addon.UI.Widgets

function Destroy:Create(parent)
  Widgets:Heading(parent, L.DESTROY_TEXT)
  self:AddGeneral(parent)
end

function Destroy:AddGeneral(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.GENERAL_TEXT,
    fullWidth = true
  })

  -- Auto Open
  Widgets:CheckBoxSlider({
    parent = parent,
    checkBox = {
      label = L.AUTO_OPEN_TEXT,
      tooltip = L.AUTO_OPEN_DESTROY_TOOLTIP,
      get = function() return DB.Profile.destroy.autoOpen.enabled end,
      set = function(value) DB.Profile.destroy.autoOpen.enabled = value end
    },
    slider = {
      label = L.THRESHOLD_TEXT,
      tooltip = L.AUTO_OPTION_THRESHOLD_TOOLTIP:format(
        "|cFFFFD100"  .. L.AUTO_OPEN_TEXT .. "|r",
        "|cFFFFD100"  .. L.AUTO_OPEN_TEXT .. "|r"
      ),
      value = DB.Profile.destroy.autoOpen.value,
      min = Consts.DESTROY_AUTO_SLIDER_MIN,
      max = Consts.DESTROY_AUTO_SLIDER_MAX,
      step = Consts.DESTROY_AUTO_SLIDER_STEP,
      onValueChanged = function(_, event, value)
        DB.Profile.destroy.autoOpen.value = value
      end
    }
  })
end
