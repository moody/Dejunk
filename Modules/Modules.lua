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
  ParentFrame = DFL.ParentFrame:Create(),
  TitleFrame = DFL.ChildFrame:Create(),
  DejunkChildFrame = DFL.ChildFrame:Create(),
  DestroyChildFrame = DFL.ChildFrame:Create(),
  TransportChildFrame = DFL.ChildFrame:Create()
}

-- /UI/Objects/
Addon.Objects = {
  ListButton = DFL:NewObjectTable(),
  ListFrame = DFL:NewObjectTable(),
  OptionsFrame = DFL:NewObjectTable()
}
