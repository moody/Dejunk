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
local TitleFrame = DJ.DejunkFrames.TitleFrame
local BasicChildFrame = DJ.DejunkFrames.BasicChildFrame
local TransportChildFrame = DJ.DejunkFrames.TransportChildFrame
local DestroyChildFrame = DJ.DejunkFrames.DestroyChildFrame

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

  -- If transport child frame is showing, show previous child
  if (ParentFrame:GetCurrentChild() == TransportChildFrame) then
    ParentFrame:SetCurrentChild(previousChild) end

  ParentFrame:Refresh()
end

-- Sets the ParentFrame's child to BasicChildFrame.
function Core:ShowBasicChild()
  assert(ParentFrame.Initialized)
  previousChild = ParentFrame:GetCurrentChild()
  TitleFrame:SetTitleToDejunk()
  ParentFrame:SetCurrentChild(BasicChildFrame)
end

-- Sets the ParentFrame's child to DestroyChildFrame.
function Core:ShowDestroyChild()
  assert(ParentFrame.Initialized)
  previousChild = ParentFrame:GetCurrentChild()
  TitleFrame:SetTitleToDestroy()
  ParentFrame:SetCurrentChild(DestroyChildFrame)
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

-- Swaps between the Dejunk and Destroy child frames.
function Core:SwapDejunkDestroyChildFrames()
  assert(ParentFrame.Initialized)

  local currentChild = ParentFrame:GetCurrentChild()

  local showDestroy = (currentChild == BasicChildFrame) or
    ((currentChild == TransportChildFrame) and (previousChild == BasicChildFrame))
  local showDejunk = (currentChild == DestroyChildFrame) or
    ((currentChild == TransportChildFrame) and (previousChild == DestroyChildFrame))

  if showDestroy then
    self:ShowDestroyChild()
  elseif showDejunk then
    self:ShowBasicChild()
  else
    error("Something went wrong :(")
  end
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
  local lastItemLink = nil
  local lastDejunkText = nil
  local lastTipText = nil

  local function OnTooltipSetItem(self, ...)
    if not DejunkGlobal.ItemTooltip then return end

    -- Validate item link
  	local itemLink = select(2, self:GetItem())
    if not itemLink then return end

    -- If the current item is the same as last, just re-show last tooltip
    if (lastItemLink == itemLink) then
      self:AddDoubleLine(lastDejunkText, lastTipText)
      return
    end

    -- Find item in bags
    local bag, slot = Tools:FindItemInBags(itemLink)
    if not (bag and slot) then return end

    local item = Tools:GetItemFromBag(bag, slot)
    if not item then return end

    -- Return if item cannot be sold
    if item.NoValue or not Tools:ItemCanBeSold(item.Price, item.Quality) then return end

    -- Display an appropriate tooltip if the item is junk
    local isJunkItem = Dejunker:IsJunkItem(item)
    local dejunkText = Tools:GetColorString(format("%s:", L.DEJUNK_TEXT), Colors.LabelText)
    local tipText = (isJunkItem and Tools:GetColorString(L.ITEM_WILL_BE_SOLD, Colors.DefaultColors.Inclusions)) or
      Tools:GetColorString(L.ITEM_WILL_NOT_BE_SOLD, Colors.DefaultColors.Exclusions)

    self:AddDoubleLine(dejunkText, tipText)
    lastItemLink = itemLink
    lastDejunkText = dejunkText
    lastTipText = tipText
  end

  GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
end
