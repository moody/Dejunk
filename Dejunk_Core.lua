-- Dejunk_Core: initializes Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Core = DJ.Core

local Colors = DJ.Colors
local DejunkDB = DJ.DejunkDB
local Dejunker = DJ.Dejunker
local ListManager = DJ.ListManager
local Tools = DJ.Tools
local ParentFrame = DJ.DejunkFrames.ParentFrame
local BasicChildFrame = DJ.DejunkFrames.BasicChildFrame
local TransportChildFrame = DJ.DejunkFrames.TransportChildFrame

--[[
//*******************************************************************
//                            Core Frame
//*******************************************************************
--]]

local coreFrame = CreateFrame("Frame", AddonName.."CoreFrame")

function coreFrame:OnEvent(event, ...)
  if (event == "PLAYER_LOGIN") then
    self:UnregisterEvent(event)
    Core:Initialize()
  end
end

coreFrame:SetScript("OnEvent", coreFrame.OnEvent)
coreFrame:RegisterEvent("PLAYER_LOGIN")

--[[
//*******************************************************************
//                      Core General Functions
//*******************************************************************
--]]

-- Initializes modules.
function Core:Initialize()
  DejunkDB:Initialize()
  Colors:Initialize()
  ListManager:Initialize()
  DJ.Consts:Initialize()
  DJ.MerchantButton:Initialize()
  DJ.MinimapIcon:Initialize()

  -- Setup slash command
	SLASH_DEJUNK1 = "/dejunk"
	SlashCmdList["DEJUNK"] = function (msg, editBox)
		self:ToggleGUI() end
end

-- Prints a formatted message ("[Dejunk] msg").
-- @param msg - the message to print
function Core:Print(msg)
  if DejunkDB.SV.SilentMode then return end

  local title = Tools:GetColorString("[Dejunk]",
    Colors:GetColor(Colors.LabelText))

  print(format("%s %s", title, msg))
end

--[[
//*******************************************************************
//                          Core Functions
//*******************************************************************
--]]

local previousChild = nil

-- Toggles Dejunk's GUI.
function Core:ToggleGUI()
  if not ParentFrame.Initialized then
    ParentFrame:Initialize()
    ParentFrame:SetCurrentChild(BasicChildFrame)
  end

  ParentFrame:Toggle()
end

-- Enables Dejunk's GUI.
function Core:EnableGUI()
  if not ParentFrame.Initialized then return end
  ParentFrame:Enable()
end

-- Disables Dejunk's GUI.
function Core:DisableGUI()
  if not ParentFrame.Initialized then return end
  ParentFrame:Disable()
end

-- Switches between global and character specific settings.
function Core:ToggleCharacterSpecificSettings()
  DejunkPerChar.UseGlobal = not DejunkPerChar.UseGlobal
  DejunkDB:Update()
  ListManager:Update()

  if (ParentFrame:GetCurrentChild() ~= BasicChildFrame) then
    ParentFrame:SetCurrentChild(BasicChildFrame) end

  ParentFrame:Refresh()
end

-- Sets the ParentFrame's child to BasicChildFrame.
function Core:ShowBasicChild()
  previousChild = nil
  ParentFrame:SetCurrentChild(BasicChildFrame)
end

-- Sets the ParentFrame's child to TransportChildFrame.
-- @param listName - the name of the list used for transport operations
-- @param transportType - the type of transport operations to perform
function Core:ShowTransportChild(listName, transportType)
  previousChild = ParentFrame:GetCurrentChild()

  ParentFrame:SetCurrentChild(TransportChildFrame, function()
    TransportChildFrame:SetData(listName, transportType)
  end)
end

-- Sets the ParentFrame's child to the previously displayed child.
function Core:ShowPreviousChild()
  if not previousChild then return end
  ParentFrame:SetCurrentChild(previousChild)
end

--[[
//*******************************************************************
//                            Tooltip Hook
//*******************************************************************
--]]

do
  local tooltipAdded = false

  local function OnTooltipSetItem(self, ...)
  	if not DejunkGlobal.ItemTooltip or tooltipAdded then return end

    -- Validate item link
  	local itemLink = select(2, self:GetItem())
    if not itemLink then return end

    -- Find item in bags
    local bag, slot = Tools:FindItemInBags(itemLink)
    if not (bag and slot) then return end

    local item = Tools:GetItemFromBag(bag, slot)
    if not item then return end

    -- Return if item cannot be sold
    if item.NoValue or not Tools:ItemCanBeSold(item.Price, item.Quality) then return end

    -- Display an appropriate tooltip if the item is junk
    local isJunkItem = Dejunker:IsJunkItem(item)
    local dejunkText = Tools:GetColorString(format("%s:", AddonName), Colors.LabelText)
    local tipText = (isJunkItem and Tools:GetColorString(L.ITEM_WILL_BE_SOLD, Colors.DefaultColors.Inclusions)) or
      Tools:GetColorString(L.ITEM_WILL_NOT_BE_SOLD, Colors.DefaultColors.Exclusions)

    self:AddDoubleLine(dejunkText, tipText)
    tooltipAdded = true
  end

  local function OnTooltipCleared(self, ...)
     tooltipAdded = false
  end

  GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
  GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
end
