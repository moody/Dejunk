-- Modules: initializes all of Dejunk's modules (tables) to circumvent load order issues.

local AddonName, Addon = ...

local DFL = LibStub("DethsFrameLib-1.0")

-- Libs
Addon.Libs = {
  L = LibStub('AceLocale-3.0'):GetLocale(AddonName),
  LDB = LibStub("LibDataBroker-1.1"),
  LDBIcon = LibStub("LibDBIcon-1.0"),
  DBL = LibStub("DethsBagLib-1.0"),
  DCL = LibStub("DethsColorLib-1.0"),
  DFL = DFL
}

-- Initialize Dejunk tables
Addon.Core = {}

Addon.Consts = {}
Addon.Colors = {}
Addon.DejunkDB = {}
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
  ParentFrame = DFL.Factory.ParentFrame:Create(),
  TitleFrame = DFL.Factory.ChildFrame:Create(),
  DejunkChildFrame = DFL.Factory.ChildFrame:Create(),
  DestroyChildFrame = DFL.Factory.ChildFrame:Create(),
  TransportChildFrame = DFL.Factory.ChildFrame:Create()
}
