local AddonName, Addon = ...

-- Version flags
Addon.IS_RETAIL = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
Addon.IS_CLASSIC = not Addon.IS_RETAIL

-- Libs
Addon.Libs = {
  AceGUI = _G.LibStub("AceGUI-3.0"),
  L = _G.LibStub("AceLocale-3.0"):GetLocale(AddonName),
  LDB = _G.LibStub("LibDataBroker-1.1"),
  LDBIcon = _G.LibStub("LibDBIcon-1.0"),
  DBL = Addon.DethsBagLib,
  DCL = Addon.DethsColorLib,
  DTL = _G.DethsLibLoader("DethsTooltipLib", "1.0")
}

-- Initialize Dejunk tables
Addon.Core = _G.DethsLibLoader("DethsAddonLib", "1.0"):Create(AddonName)

Addon.Consts = {}
Addon.Colors = {
  Primary = "4FAFE3FF",
  Red = "E34F4FFF",
  Green = "4FE34FFF",
  Yellow = "E3E34FFF"
}
Addon.DB = {}
Addon.EventManager = {}
Addon.Filters = {}
Addon.ListHelper = {}
Addon.Tools = {}

Addon.Confirmer = {}
Addon.Dejunker = {}
Addon.Destroyer = {}
Addon.Repairer = {}

-- /UI/
Addon.MerchantButton = {} -- TODO: add to Addon.UI
Addon.MinimapIcon = {} -- TODO: add to Addon.UI

Addon.UI = {
  Utils = {},
  Groups = {
    General = {},
    Sell = {},
    Destroy = {},
    Inclusions = {},
    Exclusions = {},
    Destroyables = {},
    Undestroyables = {},
    Profiles = {}
  }
}
