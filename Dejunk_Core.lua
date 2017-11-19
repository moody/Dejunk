-- Dejunk_Core: initializes Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Core = DJ.Core

local Colors = DJ.Colors
local DejunkDB = DJ.DejunkDB
local Dejunker = DJ.Dejunker
local Destroyer = DJ.Destroyer
local ListManager = DJ.ListManager
local Tools = DJ.Tools
local ParentFrame = DJ.DejunkFrames.ParentFrame
local TitleFrame = DJ.DejunkFrames.TitleFrame
local DejunkChildFrame = DJ.DejunkFrames.DejunkChildFrame
local TransportChildFrame = DJ.DejunkFrames.TransportChildFrame
local DestroyChildFrame = DJ.DejunkFrames.DestroyChildFrame

-- ============================================================================
--                                 Core Frame
-- ============================================================================

local coreFrame = CreateFrame("Frame", AddonName.."CoreFrame")

function coreFrame:OnEvent(event, ...)
  if (event == "PLAYER_LOGIN") then
    self:UnregisterEvent(event)
    Core:Initialize()
  end
end

coreFrame:SetScript("OnEvent", coreFrame.OnEvent)
coreFrame:RegisterEvent("PLAYER_LOGIN")

-- ============================================================================
--                              General Functions
-- ============================================================================

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

-- Attempts to print a message if verbose mode is enabled.
-- @param msg - the message to print
function Core:PrintVerbose(msg)
  if DejunkDB.SV.VerboseMode then Core:Print(msg) end
end

-- Returns true if the dejunking process can be safely started,
-- and false plus a reason message otherwise.
-- @return bool, string or nil
function Core:CanDejunk()
  if Dejunker:IsDejunking() then
    return false, L.DEJUNKING_IN_PROGRESS
  end

  if Destroyer:IsDestroying() then
    return false, L.CANNOT_DEJUNK_WHILE_DESTROYING
  end

  if ListManager:IsParsing(ListManager.Inclusions) or
     ListManager:IsParsing(ListManager.Exclusions) then
    return false, format(L.CANNOT_DEJUNK_WHILE_LISTS_UPDATING,
      Tools:GetColoredListName(ListManager.Inclusions),
      Tools:GetColoredListName(ListManager.Exclusions))
  end

  return true
end

-- Returns true if the destroying process can be safely started,
-- and false plus a reason message otherwise.
-- @return bool, string or nil
function Core:CanDestroy()
  if Destroyer:IsDestroying() then
    return false, L.DESTROYING_IN_PROGRESS
  end

  if Dejunker:IsDejunking() then
    return false, L.CANNOT_DESTROY_WHILE_DEJUNKING
  end

  if ListManager:IsParsing(ListManager.Destroyables) then
    return false, format(L.CANNOT_DESTROY_WHILE_LIST_UPDATING,
      Tools:GetColoredListName(ListManager.Destroyables))
  end

  return true
end

-- Returns true if Dejunk is busy dejunking, destroying, or parsing list data.
-- @return - boolean
function Core:IsBusy()
  return Dejunker:IsDejunking() or Destroyer:IsDestroying() or ListManager:IsParsing()
end

-- ============================================================================
--                                 UI Functions
-- ============================================================================

local previousChild = nil

-- Toggles Dejunk's GUI.
function Core:ToggleGUI()
  if not ParentFrame.Initialized then
    ParentFrame:Initialize() end
  if not ParentFrame:GetCurrentChild() then
    ParentFrame:SetCurrentChild(DejunkChildFrame) end

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

-- Sets the ParentFrame's child to DejunkChildFrame.
function Core:ShowDejunkChild()
  assert(ParentFrame.Initialized)
  previousChild = ParentFrame:GetCurrentChild()
  TitleFrame:SetTitleToDejunk()
  ParentFrame:SetCurrentChild(DejunkChildFrame)
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

  local showDestroy = (currentChild == DejunkChildFrame) or
    ((currentChild == TransportChildFrame) and (previousChild == DejunkChildFrame))
  local showDejunk = (currentChild == DestroyChildFrame) or
    ((currentChild == TransportChildFrame) and (previousChild == DestroyChildFrame))

  if showDestroy then
    self:ShowDestroyChild()
  elseif showDejunk then
    self:ShowDejunkChild()
  else
    error("Something went wrong :(")
  end
end

-- Sets the ParentFrame's child to the previously displayed child.
function Core:ShowPreviousChild()
  if not previousChild then return end
  ParentFrame:SetCurrentChild(previousChild)
end

-- ============================================================================
--                                Tooltip Hook
-- ============================================================================

do
  local function setBagItem(self, bag, slot)
    if not DejunkGlobal.ItemTooltip then return end

    -- Get item
    local item = Tools:GetItemFromBag(bag, slot)
    if not item then return end

    -- Return if item cannot be sold
    if item.NoValue or not Tools:ItemCanBeSold(item.Price, item.Quality) then return end

    -- Display an appropriate tooltip if the item is junk
    local dejunkText = Tools:GetColorString(format("%s:", L.DEJUNK_TEXT), Colors.LabelText)
    local isJunkItem, reasonText = Dejunker:IsJunkItem(item)
    local tipText = isJunkItem and
      Tools:GetColorString((IsAltKeyDown() and reasonText or L.ITEM_WILL_BE_SOLD), Colors.Inclusions) or
      Tools:GetColorString((IsAltKeyDown() and reasonText or L.ITEM_WILL_NOT_BE_SOLD), Colors.Exclusions)

    self:AddDoubleLine(dejunkText, tipText)
    self:Show()
  end

  hooksecurefunc(GameTooltip, "SetBagItem", setBagItem)
end
