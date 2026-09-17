local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Commands = Addon:GetModule("Commands")
local L = Addon:GetModule("Locale")
local Widgets = Addon:GetModule("Widgets")

local categoryFrame = Widgets:Frame({ name = "DejunkAddOnCategoryFrame" })

local optionsButton = Widgets:Button({
  parent = categoryFrame,
  labelText = L.TOGGLE_OPTIONS_FRAME,
  points = {
    { "TOPLEFT", categoryFrame, "TOPLEFT", Widgets:Padding(2), -Widgets:Padding(2) },
    { "TOPRIGHT", categoryFrame, "TOPRIGHT", -Widgets:Padding(2), -Widgets:Padding(2) }
  },
  onClick = Commands.options
})

local profilesButton = Widgets:Button({
  parent = categoryFrame,
  labelText = L.TOGGLE_PROFILES_FRAME,
  points = {
    { "TOPLEFT", optionsButton, "BOTTOMLEFT", 0, -Widgets:Padding() },
    { "TOPRIGHT", optionsButton, "BOTTOMRIGHT", 0, -Widgets:Padding() }
  },
  onClick = Commands.profiles
})

Widgets:Button({
  parent = categoryFrame,
  labelText = L.TOGGLE_JUNK_FRAME,
  points = {
    { "TOPLEFT", profilesButton, "BOTTOMLEFT", 0, -Widgets:Padding() },
    { "TOPRIGHT", profilesButton, "BOTTOMRIGHT", 0, -Widgets:Padding() }
  },
  onClick = Commands.junk
})

local category = Settings.RegisterCanvasLayoutCategory(categoryFrame, ADDON_NAME)
category.ID = ADDON_NAME
Settings.RegisterAddOnCategory(category)
