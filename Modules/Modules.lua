-- Modules: initializes all of Dejunk's modules (tables) to circumvent load order issues.

local AddonName, Addon = ...

-- Libs
Addon.Libs = {
  L = LibStub('AceLocale-3.0'):GetLocale(AddonName),
  LDB = LibStub("LibDataBroker-1.1"),
  LDBIcon = LibStub("LibDBIcon-1.0"),
  DBL = LibStub("DethsBagLib-1.0"),
  DCL = LibStub("DethsColorLib-1.0"),
  DFL = LibStub("DethsFrameLib-1.0")
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

-- /UI/FrameFactory/
Addon.FrameCreator = {}
Addon.FrameFactory = {}

-- /UI/DejunkFrames/
Addon.DejunkFrames = {
  ParentFrame = {},
  TitleFrame = {},
  DejunkChildFrame = {},
  DejunkChildOptionsFrame = {},
  DejunkChildListsFrame = {},
  DestroyChildFrame = {},
  DestroyChildOptionsFrame = {},
  DestroyChildListFrame = {},
  TransportChildFrame = {}
}
