--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk_DejunkDB: provides Dejunk modules easy access to saved variables.

local AddonName, DJ = ...

-- Dejunk
local DejunkDB = DJ.DejunkDB

-- Variables
DejunkDB.Initialized = false
DejunkDB.SV = nil

--[[
//*******************************************************************
//                        Database Functions
//*******************************************************************
--]]

-- Initializes the database.
function DejunkDB:Initialize()
  if self.Initialized then return end

  if DejunkGlobal == nil then
    DejunkGlobal = self:GetDefaultGlobalSettings()
  end

  if DejunkPerChar == nil then
    DejunkPerChar = self:GetDefaultPerCharSettings()
  end

  self:ConvertListFormat()
  self:Update()

  self.Initialized = true
end

-- Converts legacy lists to the newest format.
function DejunkDB:ConvertListFormat()
  local convert = function(list)
    local newEntries = {}

    for k, v in pairs(list) do
      if (type(v) == "table") then
        local itemID = tostring(v.ItemID)
        newEntries[itemID] = true
        list[k] = nil
      end
    end

    for k in pairs(newEntries) do
      list[k] = true end
  end

  for k, v in pairs({DejunkGlobal, DejunkPerChar}) do
    convert(v.Inclusions) convert(v.Exclusions) end
end

-- Updates the Database's reference to the saved variables.
function DejunkDB:Update()
  if DejunkPerChar.UseGlobal then
    self.SV = DejunkGlobal
  else -- Use character settings
    self.SV = DejunkPerChar
  end
end

--[[
//*******************************************************************
//                        Settings Functions
//*******************************************************************
--]]

-- Returns the default saved variables.
function DejunkDB:Defaults()
	return
	{
		-- Sell All options
		SellPoor = true,
		SellCommon = false,
		SellUncommon = false,
		SellRare = false,
		SellEpic = false,

		-- Additional options
		AutoSell = false,
    AutoRepair = false,
		SafeMode = true,
		SilentMode = false,

		-- Lists, table of itemIDs: { ["itemID"] = true }
		Inclusions = {},
		Exclusions = {},
	}
end

-- Returns the default global saved variables.
function DejunkDB:GetDefaultGlobalSettings()
  local settings = self:Defaults()

  -- Add
  settings.ColorScheme = "Default"

  return settings
end

-- Returns the default per character saved variables.
function DejunkDB:GetDefaultPerCharSettings()
  local settings = self:Defaults()

  -- Add
  settings.UseGlobal = true

  return settings
end

-- Add default key strings to DejunkDB
local keys = DejunkDB:Defaults()
for k in pairs(keys) do DejunkDB[k] = k end
keys = nil
