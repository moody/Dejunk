local AddonName, Addon = ...

-- Libs
Addon.Libs = {
  AceGUI = LibStub('AceGUI-3.0'),
  L = LibStub('AceLocale-3.0'):GetLocale(AddonName),
  LDB = LibStub("LibDataBroker-1.1"),
  LDBIcon = LibStub("LibDBIcon-1.0"),
  DBL = DethsLibLoader("DethsBagLib", "1.1"),
  DCL = DethsLibLoader("DethsColorLib", "1.1"),
  DTL = DethsLibLoader("DethsTooltipLib", "1.0")
}

-- Initialize Dejunk tables
Addon.Core = DethsLibLoader("DethsAddonLib", "1.0"):Create(AddonName)

Addon.Consts = {}
Addon.Colors = {}
Addon.DB = {}
Addon.ListManager = {}
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
    Ignore = {},
    Destroy = {},
    Inclusions = {},
    Exclusions = {},
    Destroyables = {},
    Profiles = {}
  }
}
