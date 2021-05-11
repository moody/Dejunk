local AddonName, Addon = ...
Addon.VERSION = _G.GetAddOnMetadata(AddonName, "Version")

-- Game version flags
Addon.IS_RETAIL = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
Addon.IS_CLASSIC = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC
Addon.IS_BC = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC

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
Addon.Chat = {}

Addon.Colors = {
  Primary = "4FAFE3FF",
  Red = "E34F4FFF",
  Green = "4FE34FFF",
  Yellow = "E3E34FFF"
}

Addon.Commands = {}
Addon.Confirmer = {}
Addon.Consts = {}
Addon.Core = {}

Addon.DB = {}
Addon.DatabaseUtils = {}
Addon.GlobalVersioner = {}
Addon.ProfileVersioner = {}

Addon.Dejunker = {}
Addon.Destroyer = {}
Addon.EventManager = {}
Addon.Events = {}
Addon.Filters = {}

 do -- ItemQuality
  local ItemQuality = _G.Enum.ItemQuality
  Addon.ItemQuality = {
    Poor = _G.LE_ITEM_QUALITY_POOR or ItemQuality.Poor,
    Common = _G.LE_ITEM_QUALITY_COMMON or ItemQuality.Common,
    Uncommon = _G.LE_ITEM_QUALITY_UNCOMMON or ItemQuality.Uncommon,
    Rare = _G.LE_ITEM_QUALITY_RARE or ItemQuality.Rare,
    Epic = _G.LE_ITEM_QUALITY_EPIC or ItemQuality.Epic,
    Legendary = _G.LE_ITEM_QUALITY_LEGENDARY or ItemQuality.Legendary,
    Artifact = _G.LE_ITEM_QUALITY_ARTIFACT or ItemQuality.Artifact,
    Heirloom = _G.LE_ITEM_QUALITY_HEIRLOOM or ItemQuality.Heirloom,
    WoWToken = _G.LE_ITEM_QUALITY_WOW_TOKEN or ItemQuality.WoWToken
  }
end

Addon.ListHelper = {}
Addon.ListMixins = {}
Addon.Lists = {}
Addon.Repairer = {}
Addon.Utils = {}

-- /ui
Addon.MinimapIcon = {}

Addon.ItemFrames = {
  Sell = {},
  Destroy = {},
}

Addon.UI = {
  Widgets = {},
  Groups = {
    General = {},

    Sell = {},
    SellInclusions = {},
    SellExclusions = {},

    Destroy = {},
    DestroyInclusions = {},
    DestroyExclusions = {},

    Commands = {},

    Profiles = {}
  },
  MerchantButton = {}
}
