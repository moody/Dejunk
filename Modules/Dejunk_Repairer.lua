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

-- Dejunk_Repairer: handles the process of repairing.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Repairer = DJ.Repairer

local Core = DJ.Core

-- Variables
local isRepairing = false
local guildRepairError = false
local canGuildRepair = false
local usedGuildRepair = false
local totalRepairCost = 0

--[[
//*******************************************************************
//                         Repairer Frame
//*******************************************************************
--]]

local repairFrame = CreateFrame("Frame", AddonName.."RepairerFrame")

repairFrame:SetScript("OnEvent", function(frame, event, ...)
  if (event == "UI_ERROR_MESSAGE") then
    local _, msg = ...

    if (isRepairing and (msg == ERR_GUILD_NOT_ENOUGH_MONEY)) then
      UIErrorsFrame:Clear()
      guildRepairError = true
    end
  end
end)

repairFrame:RegisterEvent("UI_ERROR_MESSAGE")

--[[
//*******************************************************************
//                        Repairing Functions
//*******************************************************************
--]]

local REPAIR_DELAY = 0.5
local repairInterval = 0

-- Starts the repairing process.
function Repairer:StartRepairing()
  isRepairing = true
  repairInterval = 0

  repairFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:PreUpdateRepairs(frame, elapsed) end)
end

-- Cancels the repairing process.
function Repairer:StopRepairing()
  repairFrame:SetScript("OnUpdate", nil)

  isRepairing = false
  guildRepairError = false
	canGuildRepair = false
	usedGuildRepair = false
	totalRepairCost = 0
end

-- Checks whether or not the Repairer is active.
-- @return - boolean
function Repairer:IsRepairing()
  return isRepairing
end

-- Used as a short delay prior to UpdateRepairs() in order to circumvent erroneous GetRepairAllCost() returns.
function Repairer:PreUpdateRepairs(frame, elapsed)
	repairInterval = (repairInterval + elapsed)

	if (repairInterval >= REPAIR_DELAY) then
		local repairCost, canRepair = GetRepairAllCost()

		if ((not canRepair) or (repairCost <= 0)) then
			self:StopRepairing()
			return
		end

		local guildBankLimit = GetGuildBankWithdrawMoney()
		canGuildRepair = (CanGuildBankRepair() and ((guildBankLimit == -1) or (guildBankLimit >= repairCost)))

		totalRepairCost = repairCost
		repairInterval = REPAIR_DELAY

		repairFrame:SetScript("OnUpdate", function(frame, elapsed)
      self:UpdateRepairs() end)
	end
end

-- Set as the OnUpdate function during the repairing process.
function Repairer:UpdateRepairs()
	if canGuildRepair and not guildRepairError then
		-- An error message will be shown if the guild bank does not have enough money,
		-- so we clear the UIErrorsFrame when the event fires while currentlyRepairing (see repairFrame OnEvent script).
		-- Also, guildRepairError will be set to true if that event occurs.
		if usedGuildRepair then
			local _, canRepair = GetRepairAllCost()

			if not canRepair then -- Guild repair should have been successful
				PlaySound("ITEM_REPAIR")

				Core:Print(format(L.REPAIRED_ALL_ITEMS_GUILD,
					GetCoinTextureString(totalRepairCost)))

				self:StopRepairing()
				return
			end

			return -- wait and see if guild repair worked
		end

		RepairAllItems(true) -- Use guild money
		usedGuildRepair = true
		return
	elseif (GetMoney() >= totalRepairCost) then
		RepairAllItems(false) -- Use player money
		PlaySound("ITEM_REPAIR")

		Core:Print(format(L.REPAIRED_ALL_ITEMS,
			GetCoinTextureString(totalRepairCost)))

		self:StopRepairing()
		return
	else -- Repairs probably impossible
		if DJ.Dejunker:IsDejunking() then return end -- Wait until junk has been sold

		Core:Print(L.REPAIRED_NO_ITEMS)

		self:StopRepairing()
		return
	end
end
