local _, Addon = ...
local CanGuildBankRepair = _G.CanGuildBankRepair
local Chat = Addon.Chat
local Confirmer = Addon.Confirmer
local DB = Addon.DB
local Dejunker = Addon.Dejunker
local E = Addon.Events
local ERR_GUILD_NOT_ENOUGH_MONEY = _G.ERR_GUILD_NOT_ENOUGH_MONEY
local EventManager = Addon.EventManager
local GetCoinTextureString = _G.GetCoinTextureString
local GetGuildBankWithdrawMoney = _G.GetGuildBankWithdrawMoney
local GetMoney = _G.GetMoney
local GetRepairAllCost = _G.GetRepairAllCost
local ITEM_REPAIR_SOUND_ID = _G.SOUNDKIT.ITEM_REPAIR
local L = Addon.Libs.L
local PlaySound = _G.PlaySound
local RepairAllItems = _G.RepairAllItems
local Repairer = Addon.Repairer

-- Variables
local REPAIR_DELAY = 0.5
local repairInterval = 0

local isRepairing = false
local totalRepairCost = 0

local canGuildRepair = false
local guildRepairError = false
local usedGuildRepair = false

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.Wow.MerchantShow, function()
	if DB.Profile.general.autoRepair then Repairer:StartRepairing() end
end)

EventManager:On(E.Wow.MerchantClosed, function()
	if isRepairing then Repairer:StopRepairing() end
end)

if Addon.IS_RETAIL then
	EventManager:On(E.Wow.UIErrorMessage, function(_, msg)
		if isRepairing and msg == ERR_GUILD_NOT_ENOUGH_MONEY then
			guildRepairError = true
		end
	end)
end

-- ============================================================================
-- OnUpdate Scripts
-- ============================================================================

-- Set as the OnUpdate function during the repairing process.
local function repairer_OnUpdate(self, elapsed)
	--[[
		NOTE: If we attempt a guild repair, a `UI_ERROR_MESSAGE` event will fire
		with the message `ERR_GUILD_NOT_ENOUGH_MONEY` if the guild bank does not
		have enough money. In that case, `guildRepairError` will be set to true.

		If it wasn't obvious, we cannot get the remaining guild withdraw amount.
		See: <OnClick> for "MerchantGuildBankRepairButton" in MerchantFrame.xml
	--]]
	if canGuildRepair and not guildRepairError then
		if usedGuildRepair then
			local _, canRepair = GetRepairAllCost()

			if not canRepair then -- Guild repair should have been successful
				PlaySound(ITEM_REPAIR_SOUND_ID)
				Chat:Print(
          L.REPAIRED_ALL_ITEMS_GUILD:format(
            GetCoinTextureString(totalRepairCost)
          )
        )
				Repairer:StopRepairing()
				return
			end

			return -- wait and see if guild repair worked
		end

		RepairAllItems(true) -- Use guild money
		usedGuildRepair = true
		return
	elseif GetMoney() >= totalRepairCost then
		RepairAllItems()
		PlaySound(ITEM_REPAIR_SOUND_ID)
		Chat:Print(
      L.REPAIRED_ALL_ITEMS:format(GetCoinTextureString(totalRepairCost))
    )
		Repairer:StopRepairing()
		return
	else -- Repairs probably impossible
		if Dejunker:IsDejunking() or Confirmer:IsConfirming("Dejunker") then
			return -- Wait until junk has been sold
		end
		Chat:Print(L.REPAIRED_NO_ITEMS)
		Repairer:StopRepairing()
		return
	end
end

-- Used as a short delay prior to UpdateRepairs() in order to circumvent erroneous GetRepairAllCost() returns.
local function start_OnUpdate(self, elapsed)
	repairInterval = (repairInterval + elapsed)

	if (repairInterval >= REPAIR_DELAY) then
		local repairCost, canRepair = GetRepairAllCost()

		if (not canRepair) or (repairCost <= 0) then
			Repairer:StopRepairing()
      return
    end

    if Addon.IS_RETAIL then
      local guildBankLimit = GetGuildBankWithdrawMoney()
      canGuildRepair =
        DB.Profile.general.useGuildRepair and
        CanGuildBankRepair() and
        (
          guildBankLimit == -1 or
          guildBankLimit >= repairCost
        )
    end

		totalRepairCost = repairCost
		repairInterval = REPAIR_DELAY

		self.OnUpdate = repairer_OnUpdate
	end
end

-- ============================================================================
-- General Functions
-- ============================================================================

-- Starts the repairing process.
function Repairer:StartRepairing()
  isRepairing = true
	repairInterval = 0
	self.OnUpdate = start_OnUpdate
end

-- Cancels the repairing process.
function Repairer:StopRepairing()
  isRepairing = false
	totalRepairCost = 0

	canGuildRepair = false
  guildRepairError = false
	usedGuildRepair = false

	self.OnUpdate = nil
end

-- Checks whether or not the Repairer is active.
-- @return - boolean
function Repairer:IsRepairing()
  return isRepairing
end
