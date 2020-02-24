local AddonName, Addon = ...
Addon.VERSION = _G.GetAddOnMetadata(AddonName, "Version")

-- Game version flags
Addon.IS_RETAIL = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
Addon.IS_CLASSIC = not Addon.IS_RETAIL

-- Libs
Addon.Libs = {
  AceGUI = _G.LibStub("AceGUI-3.0"),
  L = _G.LibStub("AceLocale-3.0"):GetLocale(AddonName),
  LDB = _G.LibStub("LibDataBroker-1.1"),
  LDBIcon = _G.LibStub("LibDBIcon-1.0"),
  DCL = Addon.DethsColorLib,
  DTL = _G.DethsLibLoader("DethsTooltipLib", "1.0")
}

-- Initialize Dejunk tables
Addon.Bags = {}

Addon.Colors = {
  Primary = "4FAFE3FF",
  Red = "E34F4FFF",
  Green = "4FE34FFF",
  Yellow = "E3E34FFF"
}

Addon.Confirmer = {}
Addon.Consts = {}
Addon.Core = {}
Addon.DB = {}
Addon.Dejunker = {}
Addon.Destroyer = {}
Addon.EventManager = {}
Addon.Events = {}
Addon.Filters = {}
Addon.ListHelper = {}
Addon.Repairer = {}
Addon.Utils = {}

-- /UI/
Addon.MinimapIcon = {} -- TODO: add to Addon.UI

Addon.UI = {
  Widgets = {},
  Groups = {
    General = {},
    Sell = {},
    Destroy = {},
    Inclusions = {},
    Exclusions = {},
    Destroyables = {},
    Undestroyables = {},
    Profiles = {}
  },
  MerchantButton = {}
}
