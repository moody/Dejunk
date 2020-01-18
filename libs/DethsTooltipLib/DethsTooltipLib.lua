-- https://github.com/moody/DethsTooltipLib

local LibName, LibVersion = "DethsTooltipLib", "1.0"
local PREFIX = format("%s_%s_", LibName, LibVersion)

-- DethsLibLoader
local DTL = DethsLibLoader:Create(LibName, LibVersion)
if not DTL then return end

-- Upvalues
local _G, assert, pairs, ipairs, strtrim, type, tostring, tremove =
      _G, assert, pairs, ipairs, strtrim, type, tostring, table.remove
local UIParent, GameTooltip = UIParent, GameTooltip

local ARMOR_CLASS = GetItemClassInfo(LE_ITEM_CLASS_ARMOR)
local WEAPON_CLASS = GetItemClassInfo(LE_ITEM_CLASS_WEAPON)

-- Table pool
local get, release do
  local pool = {}
  -- Returns a table from the pool.
  get = function() return tremove(pool) or {} end
  -- Releases a table into the pool.
  release = function(t)
    for k in pairs(t) do t[k] = nil end
    pool[#pool+1] = t
  end
end

-- ============================================================================
-- Tooltip Functions
-- ============================================================================

-- Displays a generic game tooltip.
-- @param owner - the frame the tooltip belongs to
-- @param anchorType - the anchor type ("ANCHOR_LEFT", "ANCHOR_CURSOR", etc.)
-- @param title - the title of the tooltip
-- @param ... - the body lines of the tooltip
function DTL:ShowTooltip(owner, anchorType, title, ...)
  GameTooltip:SetOwner(owner, anchorType)
  GameTooltip:SetText(title, 1.0, 0.82, 0)
  
  for i=1, select("#", ...) do
    local line = select(i, ...)
    if (type(line) == "function") then line = line() end
    GameTooltip:AddLine(line, 1, 1, 1, true)
  end
  
  GameTooltip:Show()
end

-- Displays a tooltip with hyperlink information.
-- @param owner - the frame the tooltip belongs to
-- @param anchorType - the anchor type ("ANCHOR_LEFT", "ANCHOR_CURSOR", etc.)
-- @param hyperlink - the hyperlink to use
function DTL:ShowHyperlink(owner, anchorType, hyperlink)
  GameTooltip:SetOwner(owner, anchorType)
  GameTooltip:SetHyperlink(hyperlink)
  GameTooltip:Show()
end

-- Hides the game tooltip.
function DTL:HideTooltip()
  GameTooltip:Hide()
end

-- ============================================================================
-- Scanning Helper Functions
-- ============================================================================

local tooltip = CreateFrame("GameTooltip", PREFIX.."Scanner", nil, "GameTooltipTemplate")
local tooltipTextLeft = PREFIX.."ScannerTextLeft"
local tooltipTextRight = PREFIX.."ScannerTextRight"

-- Returns all non-blank lines in the scanner tooltip.
-- @param rightSide - true for right-side scanning [optional]
local function getAllLines(rightSide)
  local textSide = rightSide and tooltipTextRight or tooltipTextLeft
  local lines = get()

  for i = 1, tooltip:NumLines() do
    local line = strtrim((_G[textSide..i]):GetText()) or ""
    if (line ~= "") then lines[#lines+1] = line end
  end

  return lines
end

-- Returns true if tooltip information is available to be scanned.
local isScannable do
  local RETRIEVING_ITEM_INFO = RETRIEVING_ITEM_INFO

  isScannable = function()
    local allLines = getAllLines()
    if (#allLines == 0) then return false end

    for _, line in pairs(allLines) do
      if (line == RETRIEVING_ITEM_INFO) then
        release(allLines)
        return false
      end
    end

    release(allLines)
    return true
  end
end

-- ============================================================================
-- Scanning Functions
-- ============================================================================

--[[
  Initializes the item in the specified bag and slot for tooltip scanning, and
  returns true if the tooltip can be scanned.

  Call this function in an if statement before calling other scanning functions,
  such as DTL:GetItemLevel(), to ensure that the results are accurate!
  
  @param bag - the bag the item resides in
  @param slot - the slot the item resides in
]]
function DTL:ScanBagSlot(bag, slot)
  tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  tooltip:SetBagItem(bag, slot)

  -- Init canGetItemLevel
  local link = GetContainerItemLink(bag, slot)
  local isItem = link and link:find("item:", 1, true)
  local class = isItem and select(2, GetItemInfoInstant(link)) or nil
  self._canGetItemLevel = class and ((class == ARMOR_CLASS) or (class == WEAPON_CLASS))

  return isScannable()
end

--[[
  Initializes the link for tooltip scanning, and returns true if the tooltip
  can be scanned.

  Call this function in an if statement before calling other scanning functions,
  such as DTL:GetItemLevel(), to ensure that the results are accurate!

  NOTE: If you have only the id of an item, quest, or spell, you can pass a
  string in place of the link: "item:id", "quest:id", or "spell:id".

  @param link - the link to scan
]]
function DTL:ScanLink(link)
  tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  tooltip:SetHyperlink(link)

  -- Init canGetItemLevel
  local isItem = link:find("item:", 1, true)
  local class = isItem and select(2, GetItemInfoInstant(link)) or nil
  self._canGetItemLevel = class and ((class == ARMOR_CLASS) or (class == WEAPON_CLASS))

  return isScannable()
end

-- Returns all left or right lines in the tooltip.
-- @param rightSide - true for right-side scanning
function DTL:GetLines(rightSide)
  return getAllLines(rightSide)
end

-- Returns true if all specified text can be found in the lines of the tooltip.
-- Example: find(false, "Linen", "Reagent") will return true for a Linen Cloth tooltip.
-- @param rightSide - true for right-side scanning
-- @param ... - the text to find in the tooltip
function DTL:Find(rightSide, ...)
  local allLines = getAllLines(rightSide)
  local n = select("#", ...)
  local wordsFound = 0
  local word

  for _, line in pairs(allLines) do
    for i=1, n do -- Loop varargs
      word = select(i, ...)
      if line:find(word, 1, true) then
        wordsFound = wordsFound + 1
        if (wordsFound == n) then
          release(allLines)
          return true
        end
      end
    end
  end
  
  release(allLines)
  return false
end

-- Returns true if the tooltip contains a line that is an exact match of the specified string.
-- @param rightSide - true for right-side scanning
-- @param text - the text to find in the tooltip
function DTL:FindExact(rightSide, text)
  local allLines = getAllLines()

  for _, line in pairs(allLines) do
    if (line == text) then
      release(allLines)
      return true
    end
  end

  release(allLines)
  return false
end

-- Returns the first tooltip line containing all specified text.
-- @param rightSide - true for right-side scanning
-- @param ... - the text to find in a single tooltip line
function DTL:FindLine(rightSide, ...)
  local allLines = getAllLines()
  local n = select("#", ...)
  local wordsFound = 0
  local word

  for _, line in pairs(allLines) do
    for i=1, n do -- Loop varargs
      word = select(i, ...)
      if line:find(word, 1, true) then
        wordsFound = wordsFound + 1
        if (wordsFound == n) then
          release(allLines)
          return line
        end
      end
    end
    -- Reset for next line
    wordsFound = 0
  end

  release(allLines)
  return nil
end

-- Returns the first match for a specified pattern in the tooltip.
-- @param rightSide - true for right-side scanning
-- @param pattern - the pattern to match
function DTL:Match(rightSide, pattern)
  local allLines = getAllLines(rightSide)
  local result
  
  for _, line in pairs(allLines) do
    result = line:match(pattern)
    if result then
      release(allLines)
      return result
    end
  end

  release(allLines)
  return nil
end

-- ============================================================================
-- Typical Scanning Functions
-- ============================================================================

local TRADEABLE_CAPTURE = BIND_TRADE_TIME_REMAINING:gsub("%%s", "(.*)")
local ITEM_LEVEL_CAPTURE = ITEM_LEVEL:gsub("%%d", "(%%d+)")

local ITEM_ACCOUNTBOUND = ITEM_ACCOUNTBOUND
local ITEM_BNETACCOUNTBOUND = ITEM_BNETACCOUNTBOUND
local ITEM_BIND_TO_ACCOUNT = ITEM_BIND_TO_ACCOUNT
local ITEM_BIND_TO_BNETACCOUNT = ITEM_BIND_TO_BNETACCOUNT
local ITEM_BIND_ON_EQUIP = ITEM_BIND_ON_EQUIP
local ITEM_BIND_ON_USE = ITEM_BIND_ON_USE
local ITEM_SOULBOUND = ITEM_SOULBOUND

-- Returns true if the item's tooltip contains ITEM_BNETACCOUNTBOUND or ITEM_ACCOUNTBOUND.
function DTL:IsAccountBound()
  return self:FindExact(false, ITEM_BNETACCOUNTBOUND) or self:FindExact(false, ITEM_ACCOUNTBOUND)
end

-- Returns true if the item's tooltip contains ITEM_BIND_TO_BNETACCOUNT or ITEM_BIND_TO_ACCOUNT.
function DTL:IsBindsToAccount()
  return self:FindExact(false, ITEM_BIND_TO_BNETACCOUNT) or self:FindExact(false, ITEM_BIND_TO_ACCOUNT)
end

-- Returns true if the item's tooltip contains ITEM_BIND_ON_USE.
function DTL:IsBindsWhenUsed()
  return self:FindExact(false, ITEM_BIND_ON_USE)
end

-- Returns true if the item's tooltip contains ITEM_BIND_ON_EQUIP.
function DTL:IsBindsWhenEquipped()
  return self:FindExact(false, ITEM_BIND_ON_EQUIP)
end

-- Returns true if the item's tooltip contains ITEM_SOULBOUND.
function DTL:IsSoulbound()
  return self:FindExact(false, ITEM_SOULBOUND)
end

-- Returns true if the item's tooltip contains BIND_TRADE_TIME_REMAINING.
function DTL:IsTradeable()
  return not not self:Match(false, TRADEABLE_CAPTURE)
end

-- Returns the number in the tooltip line containing ITEM_LEVEL, or nil.
function DTL:GetItemLevel()
  return self._canGetItemLevel and tonumber(self:Match(false, ITEM_LEVEL_CAPTURE) or "") or nil
end
