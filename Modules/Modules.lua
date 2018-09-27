-- Modules: initializes all of Dejunk's modules (tables) to circumvent load order issues.

local AddonName, Addon = ...

local DFL = DethsLibLoader("DethsFrameLib", "1.1")

-- Libs
Addon.Libs = {
  L = LibStub('AceLocale-3.0'):GetLocale(AddonName),
  LDB = LibStub("LibDataBroker-1.1"),
  LDBIcon = LibStub("LibDBIcon-1.0"),
  DBL = DethsLibLoader("DethsBagLib", "1.1"),
  DCL = DethsLibLoader("DethsColorLib", "1.1"),
  DFL = DFL,
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
Addon.MerchantButton = {}
Addon.MinimapIcon = {}

-- /UI/Frames/
Addon.Frames = {
  ParentFrame = DFL.ParentFrame:Create(),
  TitleFrame = DFL.ChildFrame:Create(),
  DejunkChildFrame = DFL.ChildFrame:Create(),
  ProfileChildFrame = DFL.ChildFrame:Create(),
  TransportChildFrame = DFL.ChildFrame:Create()
}

-- /UI/Objects/
Addon.Objects = {
  CurrencyField = DFL:NewObjectTable(),
  FauxButton = DFL:NewObjectTable(),
  FauxFrame = DFL:NewObjectTable(),
  ListButton = DFL:NewObjectTable(),
  ListFrame = DFL:NewObjectTable(),
  OptionsFrame = DFL:NewObjectTable(),
  ProfileButton = DFL:NewObjectTable(),
  ProfileFrame = DFL:NewObjectTable()
}
