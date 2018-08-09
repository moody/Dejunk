-- Core: initializes Dejunk.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DBL = Addon.Libs.DBL
local DCL = Addon.Libs.DCL

-- Modules
local Core = Addon.Core

local Colors = Addon.Colors
local DejunkDB = Addon.DejunkDB
local Confirmer = Addon.Confirmer
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local ListManager = Addon.ListManager
local Tools = Addon.Tools
local ParentFrame = Addon.Frames.ParentFrame
local TitleFrame = Addon.Frames.TitleFrame
local DejunkChildFrame = Addon.Frames.DejunkChildFrame
local TransportChildFrame = Addon.Frames.TransportChildFrame

-- ============================================================================
--                                 Core Frame
-- ============================================================================

do
  local coreFrame = CreateFrame("Frame", AddonName.."CoreFrame")

  function coreFrame:OnEvent(event, ...)
    if (event == "PLAYER_LOGIN") then
      self:UnregisterEvent(event)
      Core:Initialize()
    end
  end

  coreFrame:SetScript("OnEvent", coreFrame.OnEvent)
  coreFrame:RegisterEvent("PLAYER_LOGIN")
end

-- ============================================================================
--                              General Functions
-- ============================================================================

-- Initializes modules.
function Core:Initialize()
  DejunkDB:Initialize()
  Colors:Initialize()
  ListManager:Initialize()
  Addon.Consts:Initialize()
  Addon.MerchantButton:Initialize()
  Addon.MinimapIcon:Initialize()

  -- Setup slash command
  LibStub:GetLibrary("DethsCmdLib-1.0"):Create(AddonName, function()
    self:ToggleGUI()
  end)

  self.Initialize = nil
end

-- Prints a formatted message ("[Dejunk] msg").
-- @param msg - the message to print
function Core:Print(msg)
  if DejunkDB.SV.SilentMode then return end
  local title = DCL:ColorString("[Dejunk]", Colors.LabelText)
  print(format("%s %s", title, msg))
end

-- Attempts to print a message if verbose mode is enabled.
-- @param msg - the message to print
function Core:PrintVerbose(msg)
  if DejunkDB.SV.VerboseMode then Core:Print(msg) end
end

-- Prints a debug message ("[Dejunk Debug] title: msg").
-- @param msg - the message to print
function Core:Debug(title, msg)
  if not self.IsDebugging then return end
  local debug = DCL:ColorString("[Dejunk Debug]", Colors.Red)
  title = DCL:ColorString(title, Colors.Green)
  print(format("%s %s: %s", debug, title, msg))
end
-- Core.IsDebugging = true

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

-- Returns true if Dejunk is busy performing a critical action.
-- @return - boolean
function Core:IsBusy()
  return Dejunker:IsDejunking() or Destroyer:IsDestroying() or
    ListManager:IsParsing() or Confirmer:IsConfirming()
end

-- ============================================================================
--                                 UI Functions
-- ============================================================================

-- Toggles Dejunk's GUI.
function Core:ToggleGUI()
  ParentFrame:Initialize()
  ParentFrame:Toggle()
end

-- Enables Dejunk's GUI.
function Core:EnableGUI()
  ParentFrame:Enable()
end

-- Disables Dejunk's GUI.
function Core:DisableGUI()
  ParentFrame:Disable()
end

-- Switches between global and character specific settings.
function Core:ToggleCharacterSpecificSettings()
  DejunkDB:Toggle()
  ListManager:Update()
  ParentFrame:SetContent(DejunkChildFrame)
  ParentFrame:Refresh()
end

-- ============================================================================
--                                Tooltip Hook
-- ============================================================================

do
  local item = {}

  local function setBagItem(self, bag, slot)
    if not DejunkDB:GetGlobal("ItemTooltip") then return end

    -- Get item
    if not DBL:GetItem(bag, slot, item) then return end
    if Tools:ItemCanBeRefunded(item) then return end

    local leftText = DCL:ColorString(format("%s:", AddonName), Colors.LabelText)
    local rightText

    if not IsShiftKeyDown() then -- Dejunk tooltip
      -- Return if item cannot be sold
      if item.NoValue or not Tools:ItemCanBeSold(item) then return end
      local isJunkItem, reasonText = Dejunker:IsJunkItem(item)

      rightText = isJunkItem and
        DCL:ColorString((IsAltKeyDown() and reasonText or L.ITEM_WILL_BE_SOLD), Colors.Red) or
        DCL:ColorString((IsAltKeyDown() and reasonText or L.ITEM_WILL_NOT_BE_SOLD), Colors.Green)
    else -- Destroy tooltip
      -- Return if item cannot be destroyed
      if not Tools:ItemCanBeDestroyed(item) then return end
      local isJunkItem, reasonText = Destroyer:IsDestroyableItem(item)

      rightText = isJunkItem and
        DCL:ColorString((IsAltKeyDown() and reasonText or L.ITEM_WILL_BE_DESTROYED), Colors.Red) or
        DCL:ColorString((IsAltKeyDown() and reasonText or L.ITEM_WILL_NOT_BE_DESTROYED), Colors.Green)
    end

    self:AddLine(" ") -- blank line
    self:AddDoubleLine(leftText, rightText)
    self:Show()
  end

  hooksecurefunc(GameTooltip, "SetBagItem", setBagItem)
end
