-- Modules: initializes all of Dejunk's modules (tables) to circumvent load order issues.

local AddonName, DJ = ...

-- Initialize Dejunk tables
DJ.Core = {}

DJ.Consts = {}
DJ.Colors = {}
DJ.DejunkDB = {}
DJ.ListManager = {}
DJ.Tools = {}

DJ.Dejunker = {}
DJ.Destroyer = {}
DJ.Repairer = {}

-- /UI/
DJ.MerchantButton = {}
DJ.MinimapIcon = {}

-- /UI/FrameFactory/
DJ.FrameCreator = {}
DJ.FrameFactory = {}

-- /UI/DejunkFrames/
DJ.DejunkFrames = {
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
