-- Repairer: handles the process of repairing.

local _, Addon = ...
local CanGuildBankRepair = _G.CanGuildBankRepair
local Core = Addon.Core
local DB = Addon.DB
local Dejunker = Addon.Dejunker
local ERR_GUILD_NOT_ENOUGH_MONEY = _G.ERR_GUILD_NOT_ENOUGH_MONEY
local GetCoinTextureString = _G.GetCoinTextureString
local GetGuildBankWithdrawMoney = _G.GetGuildBankWithdrawMoney
local GetMoney = _G.GetMoney
local GetRepairAllCost = _G.GetRepairAllCost
local ITEM_REPAIR_SOUND_ID = _G.SOUNDKIT.ITEM_REPAIR
local L = Addon.Libs.L
local PlaySound = _G.PlaySound
local RepairAllItems = _G.RepairAllItems
local Repairer = Addon.Repairer
local UIErrorsFrame = _G.UIErrorsFrame

-- Variables
local REPAIR_DELAY = 0.5
local repairInterval = 0

local isRepairing = false
local totalRepairCost = 0

local canGuildRepair = false
local guildRepairError = false
local usedGuildRepair = false

-- ============================================================================
-- OnUpdate Scripts
-- ============================================================================

-- Set as the OnUpdate function during the repairing process.
local function repairer_OnUpdate(self, elapsed)
	if canGuildRepair and not guildRepairError then
		--[[
			NOTE: An error message will be shown if the guild bank does not have
			enough money, so we clear the UIErrorsFrame when the event fires while
			currentlyRepairing (see Repairer:OnEvent()).

			Also, guildRepairError will be set to true if that event occurs.

			If it wasn't obvious, we cannot get the remaining guild withdraw amount.
			See: <OnClick> for "MerchantGuildBankRepairButton" in MerchantFrame.xml
		--]]
		if usedGuildRepair then
			local _, canRepair = GetRepairAllCost()

			if not canRepair then -- Guild repair should have been successful
				PlaySound(ITEM_REPAIR_SOUND_ID)
				Core:Print(
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
		Core:Print(
      L.REPAIRED_ALL_ITEMS:format(GetCoinTextureString(totalRepairCost))
    )
		Repairer:StopRepairing()
		return
	else -- Repairs probably impossible
    if Dejunker:IsBusy() then return end -- Wait until junk has been sold
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

		if (not canRepair) or (repairCost <= 0) then
			Repairer:StopRepairing()
      return
    end

    if Addon.IS_RETAIL then
      local guildBankLimit = GetGuildBankWithdrawMoney()
      canGuildRepair =
        DB.Profile.UseGuildRepair and
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

-- Event handler.
function Repairer:OnEvent(event, ...)
	if (event == "MERCHANT_SHOW") then
		if DB.Profile.AutoRepair then self:StartRepairing() end
	elseif (event == "MERCHANT_CLOSED") then
		if self:IsRepairing() then self:StopRepairing() end
  elseif Addon.IS_RETAIL and event == "UI_ERROR_MESSAGE" then
    local _, msg = ...

    if isRepairing and msg == ERR_GUILD_NOT_ENOUGH_MONEY then
      UIErrorsFrame:Clear()
      guildRepairError = true
		end
  end
end

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
