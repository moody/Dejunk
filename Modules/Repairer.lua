-- Repairer: handles the process of repairing.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L

-- Upvalues
local ITEM_REPAIR_SOUND_ID = SOUNDKIT.ITEM_REPAIR
local ERR_GUILD_NOT_ENOUGH_MONEY = ERR_GUILD_NOT_ENOUGH_MONEY

local CanGuildBankRepair, GetCoinTextureString, GetGuildBankWithdrawMoney =
			CanGuildBankRepair, GetCoinTextureString, GetGuildBankWithdrawMoney

local GetMoney, GetRepairAllCost, PlaySound, RepairAllItems, UIErrorsFrame =
			GetMoney, GetRepairAllCost, PlaySound, RepairAllItems, UIErrorsFrame

-- Modules
local Repairer = Addon.Repairer

local Core = Addon.Core
local DejunkDB = Addon.DejunkDB

-- Variables
local REPAIR_DELAY = 0.5
local repairInterval = 0

local isRepairing = false
local totalRepairCost = 0

local canGuildRepair = false
local guildRepairError = false
local usedGuildRepair = false

-- ============================================================================
-- Repairer Frame
-- ============================================================================

local repairFrame = CreateFrame("Frame", AddonName.."RepairerFrame")

function repairFrame:OnEvent(event, ...)
  if (event == "UI_ERROR_MESSAGE") then
    local _, msg = ...

		if (isRepairing and (msg == ERR_GUILD_NOT_ENOUGH_MONEY)) then
      UIErrorsFrame:Clear()
      guildRepairError = true
    end
  end
end

repairFrame:SetScript("OnEvent", repairFrame.OnEvent)
repairFrame:RegisterEvent("UI_ERROR_MESSAGE")

-- ============================================================================
-- OnUpdate Scripts
-- ============================================================================

-- Set as the OnUpdate function during the repairing process.
local function repairer_OnUpdate(self, elapsed)
	if canGuildRepair and not guildRepairError then
		--[[
			NOTE: An error message will be shown if the guild bank does not have
			enough money, so we clear the UIErrorsFrame when the event fires while
			currentlyRepairing (see repairFrame OnEvent script).

			Also, guildRepairError will be set to true if that event occurs.

			If it wasn't obvious, we cannot get the remaining guild withdraw amount.
			See: <OnClick> for "MerchantGuildBankRepairButton" in MerchantFrame.xml
		--]]
		if usedGuildRepair then
			local _, canRepair = GetRepairAllCost()

			if not canRepair then -- Guild repair should have been successful
				PlaySound(ITEM_REPAIR_SOUND_ID)
				Core:Print(format(L.REPAIRED_ALL_ITEMS_GUILD, GetCoinTextureString(totalRepairCost)))
				Repairer:StopRepairing()
				return
			end

			return -- wait and see if guild repair worked
		end

		RepairAllItems(true) -- Use guild money
		usedGuildRepair = true
		return
	elseif (GetMoney() >= totalRepairCost) then
		RepairAllItems(false) -- Use player money
		PlaySound(ITEM_REPAIR_SOUND_ID)
		Core:Print(format(L.REPAIRED_ALL_ITEMS, GetCoinTextureString(totalRepairCost)))
		Repairer:StopRepairing()
		return
	else -- Repairs probably impossible
		if Addon.Dejunker:IsDejunking() then return end -- Wait until junk has been sold
		Core:Print(L.REPAIRED_NO_ITEMS)
		Repairer:StopRepairing()
		return
	end
end

-- Used as a short delay prior to UpdateRepairs() in order to circumvent erroneous GetRepairAllCost() returns.
local function start_OnUpdate(self, elapsed)
	repairInterval = (repairInterval + elapsed)

	if (repairInterval >= REPAIR_DELAY) then
		local repairCost, canRepair = GetRepairAllCost()

		if ((not canRepair) or (repairCost <= 0)) then
			Repairer:StopRepairing()
			return
		end

		local guildBankLimit = GetGuildBankWithdrawMoney()
		canGuildRepair = DejunkDB.SV.UseGuildRepair and
      (CanGuildBankRepair() and ((guildBankLimit == -1) or (guildBankLimit >= repairCost)))

		totalRepairCost = repairCost
		repairInterval = REPAIR_DELAY

		repairFrame:SetScript("OnUpdate", repairer_OnUpdate)
	end
end

-- ============================================================================
-- General Functions
-- ============================================================================

-- Starts the repairing process.
function Repairer:StartRepairing()
  isRepairing = true
	repairInterval = 0
	
  repairFrame:SetScript("OnUpdate", start_OnUpdate)
end

-- Cancels the repairing process.
function Repairer:StopRepairing()
  isRepairing = false
	totalRepairCost = 0

	canGuildRepair = false
  guildRepairError = false
	usedGuildRepair = false

	repairFrame:SetScript("OnUpdate", nil)
end

-- Checks whether or not the Repairer is active.
-- @return - boolean
function Repairer:IsRepairing()
  return isRepairing
end
