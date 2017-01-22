-- Dejunk by Dethanyel

local AddonName, AddonTable = ...
local AddonNameColored = "|cFF6565D6["..AddonName.."]|r"

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Constants
local Consts = 
{
	Colors =
	{
		-- Options frame colors
		OptionsFrameBG = {0, 0, 0.05, 0.95},
		
		OptionsTitle = {0.247, 0.247, 0.5},
		OptionsTitleShadow = {0.05,0.05,0.2},
		
		CloseButton   = {0.05, 0.05, 0.15, 1},
		CloseButtonHi = {0.15, 0.15, 0.3, 1},
		CloseButtonText = {0.5, 0.5, 1},
		CloseButtonHiText = {1, 1, 1},
		
		OptionsSeparator = {0.15, 0.15, 0.3},
		
		LabelText = {0.35, 0.35, 0.6},
		
		PoorText = {0.62, 0.62, 0.62},
		CommonText = {1, 1, 1},
		UncommonText = {0.12, 1, 0},
		RareText = {0, 0.44, 0.87},
		EpicText = {0.64, 0.21, 0.93},
		
		InclusionsText = {0.8, 0.247, 0.247},
		InclusionsTextHi = {0.9, 0.4, 0.4},
		
		ExclusionsText = {0.247, 0.8, 0.247},
		ExclusionsTextHi = {0.4, 0.9, 0.4},
		
		ScrollFrameBG = {0.1, 0.1, 0.2, 0.5},
		ScrollBarBG = {0.1, 0.1, 0.2, 0.5},
		ScrollBarThumb = {0.1, 0.1, 0.2, 1},
		ScrollBarThumbHi = {0.15, 0.15, 0.3, 1},
		ScrollItem = {0.1, 0.1, 0.2, 1},
		ScrollItemHi = {0.15, 0.15, 0.3, 1},
	},
	
	Text =
	{
		InclusionsColored = "|cFFCC3F3F"..L.INCLUSIONS_TEXT.."|r",
		ExclusionsColored = "|cFF3FCC3F"..L.EXCLUSIONS_TEXT.."|r",
	}
}

-- Dejunking variables
local DejunkDB = nil

local currentlyDejunking = false
local currentlySelling = false
local currentlyProfiting = false

local itemsToSell = {}
local soldItems = {}

local totalProfit = 0
local sellInterval = 0

-- Repairing variables
local currentlyRepairing = false
local guildRepairError = false
local canGuildRepair = false
local usedGuildRepair = false

local totalRepairCost = 0
local repairInterval = 0

-- Upvalues
local find = string.find
local format = string.format
local match = string.match

local sort = table.sort
local remove = table.remove

local unpack = unpack
local pairs = pairs
local ipairs = ipairs

--[[
//*******************************************************************
//  					    SavedVariables
//*******************************************************************
--]]

function Dejunk_GetDefaultSettings()
	return
	{
		-- Sell All options
		SellPoor = true,
		SellCommon = false,
		SellUncommon = false,
		SellRare = false,
		SellEpic = false,
		
		-- Selling options
		AutoSell = false,
		SafeMode = true,
		AutoRepair = false,
		SilentMode = false,
		
		-- Inclusions/Exclusions table
		Inclusions =
		{
			--[[ Format, order doesn't matter
			{
				Name,
				Quality,
				Color,
				Texture,
				ItemID
			},
			--]]
		},
		
		Exclusions = {}, -- Same format as Inclusions
		
		-- SavedVariablesPerCharacter only:
		-- UseGlobal = bool
	}
end

function Dejunk_UpdateDatabase()
	if DejunkGlobal == nil then
		DejunkGlobal = Dejunk_GetDefaultSettings()
	end	
	
	if DejunkPerChar == nil then
		DejunkPerChar = Dejunk_GetDefaultSettings()
		DejunkPerChar.UseGlobal = true
	end
	
	if DejunkPerChar.UseGlobal then
		DejunkDB = DejunkGlobal
	else -- Use character settings
		DejunkDB = DejunkPerChar
	end
end

-------------------------------------------------------------

function Dejunk_Print(msg)
	if DejunkDB.SilentMode then return end
	
	print(string.format("%s %s", AddonNameColored, msg))
end

--[[
//*******************************************************************
//  					   Dejunk Frame Events
//*******************************************************************
--]]

function Dejunk_OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
end

function Dejunk_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		if ... == AddonName then
			self:UnregisterEvent("ADDON_LOADED")
			Dejunk_Initialize()
		end
	elseif event == "UI_ERROR_MESSAGE" then
		local _, msg = ...
		
		if currentlyDejunking then
			if msg == ERR_INTERNAL_BAG_ERROR then
				UIErrorsFrame:Clear()
			elseif msg == ERR_VENDOR_DOESNT_BUY then
				UIErrorsFrame:Clear()
				Dejunk_Print(L.VENDOR_DOESNT_BUY)
				Dejunk_StopDejunking()
			end
		end
		
		if currentlyRepairing then
			if msg == ERR_GUILD_NOT_ENOUGH_MONEY then
				UIErrorsFrame:Clear()
				guildRepairError = true
			end
		end
	end
end

function DejunkButton_OnShow(self)
	-- Auto Repair
	if DejunkDB.AutoRepair then
		Dejunk_StartRepairing()
	end
	
	-- Auto Sell
	if DejunkDB.AutoSell then
		Dejunk_StartDejunking()
	end
end

function DejunkButton_OnHide(self)
	if currentlySelling then
		Dejunk_StopSelling()
	end
	
	if currentlyRepairing then
		Dejunk_StopRepairing()
	end
end

function DejunkButton_OnClick(self, button, down)
	if button == "LeftButton" then
		Dejunk_StartDejunking()
	elseif button == "RightButton" then
		Dejunk_ShowOptionsFrame()
	end
end

function DejunkButton_OnEnter(self)
	Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		AddonName, L.DEJUNK_BUTTON_TOOLTIP)
end

function DejunkButton_OnLeave(self)
	GameTooltip:Hide()
end

--[[
//*******************************************************************
//  						Dejunk General
//*******************************************************************
--]]

function Dejunk_Initialize()
	-- Saved variables
	Dejunk_UpdateDatabase()
	
	-- Options frame
	Dejunk_CreateOptionsFrame()
	
	-- Setup slash command
	SLASH_DEJUNK1 = "/dejunk"
	SlashCmdList["DEJUNK"] = function (msg, editBox)
		Dejunk_ShowOptionsFrame()
	end
end

----------------------------------------------------------------------

function Dejunk_StartDejunking()
	if currentlyDejunking then return end
	currentlyDejunking = true
	
	DejunkButton:Disable()
	Dejunk_LockOptionSettings()
	
	local allItemsCached = true
	
	-- Iterate over bag slots
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(bag)
		
		for slot = 1, slots do
			local itemID = GetContainerItemID(bag, slot)
			
			if itemID then
				local name = GetItemInfo(itemID)
				if not name then allItemsCached = false end -- name = nil if item is not in cache.
				
				local texture, quantity, locked, quality, readable, lootable, 
					itemLink, isFiltered, hasNoValue, itemID = GetContainerItemInfo(bag, slot)
				
				if itemLink and texture and quality and quantity and not locked and not hasNoValue then
					local price = select(11, GetItemInfo(itemLink)) -- Incorrect prices on scaled/upgraded items unless itemLink is used.
					
					if name and price then
						if Dejunk_IsJunk(itemID, price, quality) then							
							local item = {}
							
							item.Bag = bag
							item.Slot = slot
							item.ItemID = itemID
							item.ItemLink = itemLink
							item.Name = name
							item.Quality = quality
							item.Texture = texture
							item.Quantity = quantity
							item.Price = price
							
							itemsToSell[#itemsToSell+1] = item
						end
					end
				end
			end
		end
	end
	
	if not allItemsCached then
		if #itemsToSell > 0 then
			Dejunk_Print(L.ONLY_SELLING_CACHED)
		else
			Dejunk_Print(L.NO_CACHED_JUNK_ITEMS)
			Dejunk_StopDejunking()
			return
		end
	end
	
	Dejunk_StartSelling()
end

function Dejunk_IsJunk(itemID, price, quality)
	-- Some items which cannot be sold do not return a true noValue from GetContainerItemInfo
	if not Dejunk_ItemCanBeDejunked(price, quality) then return false end
	
	-- Sell if quality check button is checked
	if (quality == LE_ITEM_QUALITY_POOR 	and DejunkDB.SellPoor) or
	   (quality == LE_ITEM_QUALITY_COMMON 	and DejunkDB.SellCommon) or
	   (quality == LE_ITEM_QUALITY_UNCOMMON	and DejunkDB.SellUncommon) or
	   (quality == LE_ITEM_QUALITY_RARE 	and DejunkDB.SellRare) or
	   (quality == LE_ITEM_QUALITY_EPIC 	and DejunkDB.SellEpic) then
	   -- But don't sell if item is excluded
		if Dejunk_ScrollFrameHasItem(DejunkOptionsFrame.ExclusionsFrame.ScrollFrame, itemID) then
			return false
		else
			return true
		end
	-- Sell if item is included
	elseif Dejunk_ScrollFrameHasItem(DejunkOptionsFrame.InclusionsFrame.ScrollFrame, itemID) then
		return true
	-- Otherwise, don't sell
	else
		return false
	end
end

function Dejunk_ItemCanBeDejunked(price, quality)
	return (price > 0 and (quality >= LE_ITEM_QUALITY_POOR and quality <= LE_ITEM_QUALITY_EPIC))
end

--------------------- SELLING

function Dejunk_StartSelling()
	if #itemsToSell <= 0 then
		Dejunk_Print(L.NO_JUNK_ITEMS)
		Dejunk_StopDejunking()
		return
	end
	
	currentlySelling = true
	sellInterval = 0
	DejunkFrame:SetScript("OnUpdate", Dejunk_SellItems)
end

function Dejunk_StopSelling()
	currentlySelling = false
	DejunkFrame:SetScript("OnUpdate", nil)
	
	Dejunk_StartProfiting()
end

-- Used as OnUpdate function when selling.
local sellUpdateTime = 0.25
function Dejunk_SellItems(self, elapsed)
	if not currentlySelling then Dejunk_StopSelling() return end
	
	sellInterval = sellInterval + elapsed
	
	if sellInterval >= sellUpdateTime then
		sellInterval = 0
		
		Dejunk_SellNextItem()
		
		if #itemsToSell <= 0 then Dejunk_StopSelling() return end
		
		if DejunkDB.SafeMode and (#soldItems == 12) then
			currentlySelling = false
			Dejunk_Print(L.SAFE_MODE_MESSAGE)
		end
	end
end

function Dejunk_SellNextItem()
	local item = remove(itemsToSell)
	if not item then return end
	
	soldItems[#soldItems+1] = item
	
	UseContainerItem(item.Bag, item.Slot)
end

-------------------- PROFITING

function Dejunk_StartProfiting()
	if #soldItems <= 0 then
		Dejunk_StopDejunking()
		return
	end
	
	currentlyProfiting = true
	totalProfit = 0
	DejunkFrame:SetScript("OnUpdate", Dejunk_CalculateProfit)
end

function Dejunk_StopProfiting()
	currentlyProfiting = false
	DejunkFrame:SetScript("OnUpdate", nil)
	
	if totalProfit > 0 then
		Dejunk_Print(format(L.SOLD_YOUR_JUNK,
			GetCoinTextureString(totalProfit)))
	end
	
	Dejunk_StopDejunking()
end

-- Used as OnUpdate function to calculate sales
function Dejunk_CalculateProfit(self, elapsed)
	if not currentlyProfiting then Dejunk_StopProfiting() return end
	
	local profit = Dejunk_CheckForNextSoldItem()
	if profit then totalProfit = totalProfit + profit end
	
	if #soldItems <= 0 then Dejunk_StopProfiting() return end
end

-- @return sold item's price if it is no longer in the player's bags
function Dejunk_CheckForNextSoldItem()
	local item = remove(soldItems, 1)
	if not item then return nil end
	
	local _, quantity, locked, _, _, _, itemLink = GetContainerItemInfo(item.Bag, item.Slot)
	
	if itemLink and (itemLink == item.ItemLink) and (quantity == item.Quantity) then
		if locked then
			-- Item probably being sold, add it back to list and try again
			soldItems[#soldItems+1] = item
			return nil
		else -- Item still in bags
			Dejunk_Print(format(L.MAY_NOT_HAVE_SOLD_ITEM, item.ItemLink))
			return nil
		end
	end
	
	-- Bag and slot is empty, the item should have sold.
	return (item.Price * item.Quantity)
end

function Dejunk_StopDejunking()
	DejunkFrame:SetScript("OnUpdate", nil)
	
	-- Cleanup of all Dejunking variables
	currentlyDejunking = false
	currentlySelling = false
	currentlyProfiting = false
	
	itemsToSell = {}
	soldItems = {}
	
	totalProfit = 0
	sellInterval = 0
	------------------------
	
	DejunkButton:Enable()
	Dejunk_UnlockOptionSettings()
end

------------------ REPAIRING

function Dejunk_StartRepairing()
	currentlyRepairing = true
	repairInterval = 0
	DejunkRepairFrame:SetScript("OnUpdate", Dejunk_PreUpdateRepairs)
end

function Dejunk_StopRepairing()
	currentlyRepairing = false
	DejunkRepairFrame:SetScript("OnUpdate", nil)
	
	-- Cleanup Repair variables
	guildRepairError = false
	canGuildRepair = false
	usedGuildRepair = false
	totalRepairCost = 0
end

-- This mosty acts as a short delay in order to circumvent erroneous GetRepairAllCost() returns
local repairUpdateTime = 0.5
function Dejunk_PreUpdateRepairs(self, elapsed)
	repairInterval = repairInterval + elapsed
	
	if repairInterval >= repairUpdateTime then
		local repairCost, canRepair = GetRepairAllCost()
		if (not canRepair) or (repairCost <= 0) then
			Dejunk_StopRepairing()
			return
		end
		
		local guildBankLimit = GetGuildBankWithdrawMoney()
		canGuildRepair = (CanGuildBankRepair() and ((guildBankLimit == -1) or (guildBankLimit >= repairCost)))
		
		totalRepairCost = repairCost
		repairInterval = repairUpdateTime
		
		self:SetScript("OnUpdate", Dejunk_UpdateRepairs)
	end
end

function Dejunk_UpdateRepairs(self, elapsed)
	if not currentlyRepairing then Dejunk_StopRepairing() return end
	
	if canGuildRepair and not guildRepairError then
		-- An error message will be shown if the guild bank does not have enough money,
		-- so we clear the UIErrorsFrame when the event fires while currentlyRepairing (see Dejunk_OnEvent).
		-- Also, guildRepairError will be set to true if that event occurs.
		if usedGuildRepair then
			local _, canRepair = GetRepairAllCost()
			
			if not canRepair then -- Guild repair was successful
				PlaySound("ITEM_REPAIR")
				
				Dejunk_Print(format(L.REPAIRED_ALL_ITEMS_GUILD,
					GetCoinTextureString(totalRepairCost)))
					
				Dejunk_StopRepairing()
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
		
		Dejunk_Print(format(L.REPAIRED_ALL_ITEMS,
			GetCoinTextureString(totalRepairCost)))
		
		Dejunk_StopRepairing()
		return
	else -- Repairs impossible
		if currentlyDejunking then return end -- Wait until junk has been sold
		
		Dejunk_Print(L.REPAIRED_NO_ITEMS)
		
		Dejunk_StopRepairing()
		return
	end
end

--[[
//*******************************************************************
//  		    Dejunk Options Frame Creation Functions
//*******************************************************************
--]]

local DejunkOptionsFrame = nil

function Dejunk_CreateOptionsFrame()
	-- Base Frame
	DejunkOptionsFrame = CreateFrame("Frame", "DejunkOptionsFrame")
	DejunkOptionsFrame:SetWidth(685)
	DejunkOptionsFrame:SetHeight(390)
	DejunkOptionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	DejunkOptionsFrame:SetFrameStrata("HIGH")
	
	DejunkOptionsFrame.Texture = Dejunk_CreateColorTexture(DejunkOptionsFrame, "BACKGROUND", Consts.Colors.OptionsFrameBG)
	
	DejunkOptionsFrame:EnableMouse(true)
	DejunkOptionsFrame:SetMovable(true)
	DejunkOptionsFrame:RegisterForDrag("LeftButton")
	DejunkOptionsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	DejunkOptionsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	DejunkOptionsFrame:SetScript("OnShow", function(self) Dejunk_ResizeOptionsFrame() end)
	table.insert(UISpecialFrames, DejunkOptionsFrame:GetName()) -- Makes the frame hide when Esc is pressed
	DejunkOptionsFrame:Hide()
	
	-- Character Specific Settings Button
	DejunkOptionsFrame.CharacterSpecific = Dejunk_CreateCheckButton("CharacterSpecific", DejunkOptionsFrame,
		"TOPLEFT", DejunkOptionsFrame, "TOPLEFT", 10, -10,
		15, "GameFontNormalSmall", L.CHARACTER_SPECIFIC_TEXT, Consts.Colors.LabelText)
	DejunkOptionsFrame.CharacterSpecific:SetChecked(not DejunkPerChar.UseGlobal)
	DejunkOptionsFrame.CharacterSpecific:SetScript("OnClick", function()
		DejunkPerChar.UseGlobal = not DejunkPerChar.UseGlobal
		Dejunk_UpdateDatabase()
		Dejunk_UpdateOptionSettings()
	end)
	DejunkOptionsFrame.CharacterSpecific:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.CHARACTER_SPECIFIC_TOOLTIP) end)
	DejunkOptionsFrame.CharacterSpecific:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Title
	DejunkOptionsFrame.Title = DejunkOptionsFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
	DejunkOptionsFrame.Title:SetPoint("TOP", 5, -8)
	DejunkOptionsFrame.Title:SetShadowColor(unpack(Consts.Colors.OptionsTitleShadow))
	DejunkOptionsFrame.Title:SetShadowOffset(2, -1.5)
	DejunkOptionsFrame.Title:SetTextColor(unpack(Consts.Colors.OptionsTitle))
	DejunkOptionsFrame.Title:SetText(L.DEJUNK_OPTIONS_TEXT)
	
	-- Close Button
	DejunkOptionsFrame.CloseButton = CreateFrame("Button", "DejunkOptionsCloseButton", DejunkOptionsFrame)
	DejunkOptionsFrame.CloseButton:SetWidth(24)
	DejunkOptionsFrame.CloseButton:SetHeight(16)
	DejunkOptionsFrame.CloseButton:SetPoint("TOPRIGHT", DejunkOptionsFrame, "TOPRIGHT", -1, -1)
	DejunkOptionsFrame.CloseButton.Backdrop = Dejunk_CreateColorTexture(DejunkOptionsFrame.CloseButton, "BACKGROUND", Consts.Colors.CloseButton)
	DejunkOptionsFrame.CloseButton.Text = DejunkOptionsFrame.CloseButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	DejunkOptionsFrame.CloseButton.Text:SetPoint("CENTER", DejunkOptionsFrame.CloseButton, "CENTER", 1.5, 0)
	DejunkOptionsFrame.CloseButton.Text:SetTextColor(unpack(Consts.Colors.CloseButtonText))
	DejunkOptionsFrame.CloseButton.Text:SetText("X")
	DejunkOptionsFrame.CloseButton:SetScript("OnClick", function(self) DejunkOptionsFrame:Hide() end)
	DejunkOptionsFrame.CloseButton:SetScript("OnEnter", function(self)
		self.Backdrop:SetColorTexture(unpack(Consts.Colors.CloseButtonHi))
		self.Text:SetTextColor(unpack(Consts.Colors.CloseButtonHiText))
	end)
	DejunkOptionsFrame.CloseButton:SetScript("OnLeave", function(self)
		self.Backdrop:SetColorTexture(unpack(Consts.Colors.CloseButton))
		self.Text:SetTextColor(unpack(Consts.Colors.CloseButtonText))
	end)
	
	-- Check button area background
	DejunkOptionsFrame.OptionsAreaTexture = DejunkOptionsFrame:CreateTexture(nil, "BORDER")
	DejunkOptionsFrame.OptionsAreaTexture:SetPoint("TOPLEFT", DejunkOptionsFrame, "TOPLEFT", 10, -45)
	DejunkOptionsFrame.OptionsAreaTexture:SetPoint("TOPRIGHT", DejunkOptionsFrame, "TOPRIGHT", -10, -45)
	DejunkOptionsFrame.OptionsAreaTexture:SetHeight(70)
	DejunkOptionsFrame.OptionsAreaTexture:SetColorTexture(unpack(Consts.Colors.ScrollFrameBG))
	DejunkOptionsFrame.OptionsAreaTexture.Spacing = 20 -- 10px left, 10px right of anchor point
	
	-- Sell All
	DejunkOptionsFrame.SellAll = DejunkOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	DejunkOptionsFrame.SellAll:SetPoint("TOPLEFT", DejunkOptionsFrame.OptionsAreaTexture, "TOPLEFT", 16, -10)
	DejunkOptionsFrame.SellAll:SetTextColor(unpack(Consts.Colors.LabelText))
	DejunkOptionsFrame.SellAll:SetText(L.SELL_ALL_TEXT)
	DejunkOptionsFrame.SellAll.Spacing = 32 -- 16px left, 16px right of anchor point
	DejunkOptionsFrame.SellAllBackdrop = Dejunk_CreateColorTexture(DejunkOptionsFrame, "OVERLAY", {0, 0, 0, 0})
	
	-- Poor Button
	DejunkOptionsFrame.SellPoor	= Dejunk_CreateCheckButton("SellPoor", DejunkOptionsFrame,
		"LEFT", DejunkOptionsFrame.SellAll, "RIGHT", 8, 0,
		30, "GameFontNormalHuge", L.POOR_TEXT, Consts.Colors.PoorText)
	DejunkOptionsFrame.SellPoor:SetChecked(DejunkDB.SellPoor)
	DejunkOptionsFrame.SellPoor:SetScript("OnClick", function() DejunkDB.SellPoor = not DejunkDB.SellPoor end)
	DejunkOptionsFrame.SellPoor:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.SELL_ALL_TOOLTIP) end)
	DejunkOptionsFrame.SellPoor:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Common Button
	DejunkOptionsFrame.SellCommon = Dejunk_CreateCheckButton("SellCommon", DejunkOptionsFrame,
		"LEFT", DejunkOptionsFrame.SellPoor.Text, "RIGHT", 8, 0,
		30, "GameFontNormalHuge", L.COMMON_TEXT, Consts.Colors.CommonText)
	DejunkOptionsFrame.SellCommon:SetChecked(DejunkDB.SellCommon)
	DejunkOptionsFrame.SellCommon:SetScript("OnClick", function() DejunkDB.SellCommon = not DejunkDB.SellCommon end)
	DejunkOptionsFrame.SellCommon:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.SELL_ALL_TOOLTIP) end)
	DejunkOptionsFrame.SellCommon:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Uncommon Button
	DejunkOptionsFrame.SellUncommon = Dejunk_CreateCheckButton("SellUncommon", DejunkOptionsFrame,
		"LEFT", DejunkOptionsFrame.SellCommon.Text, "RIGHT", 8, 0,
		30, "GameFontNormalHuge", L.UNCOMMON_TEXT, Consts.Colors.UncommonText)
	DejunkOptionsFrame.SellUncommon:SetChecked(DejunkDB.SellUncommon)
	DejunkOptionsFrame.SellUncommon:SetScript("OnClick", function() DejunkDB.SellUncommon = not DejunkDB.SellUncommon end)
	DejunkOptionsFrame.SellUncommon:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.SELL_ALL_TOOLTIP) end)
	DejunkOptionsFrame.SellUncommon:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Rare Button
	DejunkOptionsFrame.SellRare = Dejunk_CreateCheckButton("SellRare", DejunkOptionsFrame,
		"LEFT", DejunkOptionsFrame.SellUncommon.Text, "RIGHT", 8, 0,
		30, "GameFontNormalHuge", L.RARE_TEXT, Consts.Colors.RareText)
	DejunkOptionsFrame.SellRare:SetChecked(DejunkDB.SellRare)
	DejunkOptionsFrame.SellRare:SetScript("OnClick", function() DejunkDB.SellRare = not DejunkDB.SellRare end)
	DejunkOptionsFrame.SellRare:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.SELL_ALL_TOOLTIP) end)
	DejunkOptionsFrame.SellRare:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Epic Button
	DejunkOptionsFrame.SellEpic = Dejunk_CreateCheckButton("SellEpic", DejunkOptionsFrame,
		"LEFT", DejunkOptionsFrame.SellRare.Text, "RIGHT", 8, 0,
		30, "GameFontNormalHuge", L.EPIC_TEXT, Consts.Colors.EpicText)
	DejunkOptionsFrame.SellEpic:SetChecked(DejunkDB.SellEpic)
	DejunkOptionsFrame.SellEpic:SetScript("OnClick", function() DejunkDB.SellEpic = not DejunkDB.SellEpic end)
	DejunkOptionsFrame.SellEpic:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.SELL_ALL_TOOLTIP) end)
	DejunkOptionsFrame.SellEpic:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Horizontal Separator
	DejunkOptionsFrame.HorizontalSeparator = DejunkOptionsFrame:CreateTexture(nil, "OVERLAY")
	DejunkOptionsFrame.HorizontalSeparator:SetPoint("TOPLEFT", DejunkOptionsFrame.OptionsAreaTexture, "LEFT", 5, 1)
	DejunkOptionsFrame.HorizontalSeparator:SetPoint("TOPRIGHT", DejunkOptionsFrame.OptionsAreaTexture, "RIGHT", -5, 1)
	DejunkOptionsFrame.HorizontalSeparator:SetHeight(1)
	DejunkOptionsFrame.HorizontalSeparator:SetColorTexture(unpack(Consts.Colors.OptionsSeparator))
	
	-- Auto Sell
	DejunkOptionsFrame.AutoSell = Dejunk_CreateCheckButton("AutoSell", DejunkOptionsFrame, 
		"BOTTOMLEFT", DejunkOptionsFrame.OptionsAreaTexture, "BOTTOMLEFT", 14, 7,
		20, "GameFontNormal", L.AUTO_SELL_TEXT, Consts.Colors.LabelText)
	DejunkOptionsFrame.AutoSell:SetChecked(DejunkDB.AutoSell)
	DejunkOptionsFrame.AutoSell:SetScript("OnClick", function() DejunkDB.AutoSell = not DejunkDB.AutoSell end)
	DejunkOptionsFrame.AutoSell:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.AUTO_SELL_TOOLTIP) end)
	DejunkOptionsFrame.AutoSell:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	DejunkOptionsFrame.AutoSell.Spacing = 28 -- 14px left, 14px right of anchor point
	DejunkOptionsFrame.AutoSellBackdrop = Dejunk_CreateColorTexture(DejunkOptionsFrame, "OVERLAY", {0, 0, 0, 0})
	
	-- AutoRepair
	DejunkOptionsFrame.AutoRepair = Dejunk_CreateCheckButton("AutoRepair", DejunkOptionsFrame,
		"LEFT", DejunkOptionsFrame.AutoSell.Text, "RIGHT", 8, 0,
		20, "GameFontNormal", L.AUTO_REPAIR_TEXT, Consts.Colors.LabelText)
	DejunkOptionsFrame.AutoRepair:SetChecked(DejunkDB.AutoRepair)
	DejunkOptionsFrame.AutoRepair:SetScript("OnClick", function() DejunkDB.AutoRepair = not DejunkDB.AutoRepair end)
	DejunkOptionsFrame.AutoRepair:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.AUTO_REPAIR_TOOLTIP) end)
	DejunkOptionsFrame.AutoRepair:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Safe Mode
	DejunkOptionsFrame.SafeMode = Dejunk_CreateCheckButton("SafeMode", DejunkOptionsFrame,
		"LEFT", DejunkOptionsFrame.AutoRepair.Text, "RIGHT", 8, 0,
		20, "GameFontNormal", L.SAFE_MODE_TEXT, Consts.Colors.LabelText)
	DejunkOptionsFrame.SafeMode:SetChecked(DejunkDB.SafeMode)
	DejunkOptionsFrame.SafeMode:SetScript("OnClick", function() DejunkDB.SafeMode = not DejunkDB.SafeMode end)
	DejunkOptionsFrame.SafeMode:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.SAFE_MODE_TOOLTIP) end)
	DejunkOptionsFrame.SafeMode:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Silent Mode
	DejunkOptionsFrame.SilentMode = Dejunk_CreateCheckButton("SilentMode", DejunkOptionsFrame,
		"LEFT", DejunkOptionsFrame.SafeMode.Text, "RIGHT", 8, 0,
		20, "GameFontNormal", L.SILENT_MODE_TEXT, Consts.Colors.LabelText)
	DejunkOptionsFrame.SilentMode:SetChecked(DejunkDB.SilentMode)
	DejunkOptionsFrame.SilentMode:SetScript("OnClick", function() DejunkDB.SilentMode = not DejunkDB.SilentMode end)
	DejunkOptionsFrame.SilentMode:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, "ANCHOR_RIGHT",
		self.Text:GetText(), L.SILENT_MODE_TOOLTIP) end)
	DejunkOptionsFrame.SilentMode:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	-- Inclusions Scroll Frame
	DejunkOptionsFrame.InclusionsFrame = Dejunk_CreateScrollFrame("InclusionsFrame", DejunkOptionsFrame,
		L.INCLUSIONS_TEXT, L.INCLUSIONS_TOOLTIP, "ANCHOR_TOP",
		Consts.Colors.InclusionsText, Consts.Colors.InclusionsTextHi,
		DejunkDB.Inclusions, 6)
	DejunkOptionsFrame.InclusionsFrame:SetPoint("BOTTOMLEFT", 10, 10)
	Dejunk_UpdateScrollFrame(DejunkOptionsFrame.InclusionsFrame.ScrollFrame)
	
	-- Exclusions Scroll Frame
	DejunkOptionsFrame.ExclusionsFrame = Dejunk_CreateScrollFrame("ExclusionsFrame", DejunkOptionsFrame,
		L.EXCLUSIONS_TEXT, L.EXCLUSIONS_TOOLTIP, "ANCHOR_TOP",
		Consts.Colors.ExclusionsText, Consts.Colors.ExclusionsTextHi,
		DejunkDB.Exclusions, 6)
	DejunkOptionsFrame.ExclusionsFrame:SetPoint("BOTTOMRIGHT", -10, 10)
	DejunkOptionsFrame.ExclusionsFrame.ScrollFrame.ScrollBar:ClearAllPoints()
	DejunkOptionsFrame.ExclusionsFrame.ScrollFrame.ScrollBar:SetPoint("TOPRIGHT", DejunkOptionsFrame.ExclusionsFrame, "TOPLEFT", -5, 0)
	DejunkOptionsFrame.ExclusionsFrame.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", DejunkOptionsFrame.ExclusionsFrame, "BOTTOMLEFT", -5, 0)
	Dejunk_UpdateScrollFrame(DejunkOptionsFrame.ExclusionsFrame.ScrollFrame)
end

function Dejunk_CreateScrollFrame(name, parent, text, tooltip, tooltipAnchor, textColor, textColorHi, itemData, itemsToDisplay)
	local frame = CreateFrame("Frame", name, parent)
	frame:SetWidth(300)
	frame:SetHeight(227)
	frame.Backdrop = Dejunk_CreateColorTexture(frame, "BACKGROUND", Consts.Colors.ScrollFrameBG)
	
	-- Text
	frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	frame.Text:SetPoint("TOP", 0, 25)
	frame.Text:SetTextColor(unpack(textColor))
	frame.Text:SetText(text)
	
	frame.TextTooltipFrame = CreateFrame("Frame", name.."TextTooltipFrame", frame)
	frame.TextTooltipFrame:SetPoint("TOPLEFT", frame.Text, "TOPLEFT", 0, 0)
	frame.TextTooltipFrame:SetPoint("BOTTOMRIGHT", frame.Text, "BOTTOMRIGHT", 0, 0)
	frame.TextTooltipFrame:SetScript("OnEnter", function(self)
		Dejunk_GenericGameTooltipOnEnter(self, tooltipAnchor, frame.Text:GetText(),
			tooltip.."|n|n", L.SCROLL_FRAME_ADD_TOOLTIP.."|n|n", L.SCROLL_FRAME_REM_TOOLTIP)
		frame.Text:SetTextColor(unpack(textColorHi))
	end)
	frame.TextTooltipFrame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		frame.Text:SetTextColor(unpack(textColor))
	end)
	
	-- Scroll Frame
	frame.ScrollFrame = CreateFrame("ScrollFrame", name.."ScrollFrame", frame)
	frame.ScrollFrame:SetPoint("TOPLEFT", 5, -5)
	frame.ScrollFrame:SetPoint("BOTTOMRIGHT", -5, 5)
	
	frame:SetScript("OnMouseUp", function(self, button, down)
		if button == "LeftButton" and MouseIsOver(frame) then
			Dejunk_AddItemToScrollFrame(self.ScrollFrame)
		end
	end)
	
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(self, delta)
		local scrollBar = self.ScrollFrame.ScrollBar
		local value = scrollBar:GetValue() - delta
		Dejunk_OnVerticalScroll(scrollBar, value)
	end)
	
	frame.ScrollFrame.Offset = 0
	frame.ScrollFrame.ItemData = itemData
	frame.ScrollFrame.ItemsToDisplay = itemsToDisplay
	
	frame.ScrollFrame.ScrollBar = CreateFrame("Slider", name.."ScrollBar", frame.ScrollFrame)
	frame.ScrollFrame.ScrollBar:SetWidth(16)
	frame.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)
	frame.ScrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 5, 0)
	frame.ScrollFrame.ScrollBar.Backdrop = Dejunk_CreateColorTexture(frame.ScrollFrame.ScrollBar, "BACKGROUND", Consts.Colors.ScrollBarBG)
	
	frame.ScrollFrame.ScrollBar.ThumbTexture = frame.ScrollFrame.ScrollBar:CreateTexture()
	frame.ScrollFrame.ScrollBar.ThumbTexture:SetWidth(16)
	frame.ScrollFrame.ScrollBar.ThumbTexture:SetHeight(32)
	frame.ScrollFrame.ScrollBar.ThumbTexture:SetColorTexture(unpack(Consts.Colors.ScrollBarThumb))
	frame.ScrollFrame.ScrollBar:SetThumbTexture(frame.ScrollFrame.ScrollBar.ThumbTexture)
	
	frame.ScrollFrame.ScrollBar:SetMinMaxValues(0, 0)
	frame.ScrollFrame.ScrollBar:SetValueStep(1)
	frame.ScrollFrame.ScrollBar:SetValue(0)
	frame.ScrollFrame.ScrollBar:SetScript("OnValueChanged", function(self, value)
		Dejunk_OnVerticalScroll(self, value)
	end)	
	frame.ScrollFrame.ScrollBar:SetScript("OnMouseDown", function(self, button)
		self.ThumbTexture:SetColorTexture(unpack(Consts.Colors.ScrollBarThumbHi))
	end)	
	frame.ScrollFrame.ScrollBar:SetScript("OnMouseUp", function(self, button)
		self.ThumbTexture:SetColorTexture(unpack(Consts.Colors.ScrollBarThumb))
	end)
	
	frame.ScrollFrame.ScrollChild = CreateFrame("Frame", name.."ScrollChild", frame.ScrollFrame)
	frame.ScrollFrame.ScrollChild:SetPoint("TOPLEFT", frame.ScrollFrame, "TOPLEFT", 0, 0)
	frame.ScrollFrame.ScrollChild:SetWidth(1)
	frame.ScrollFrame.ScrollChild:SetHeight(1)
	
	frame.ScrollFrame:SetScrollChild(frame.ScrollFrame.ScrollChild)
	
	frame.ScrollFrame.ScrollChild.Items = {}
	for i = 1, itemsToDisplay do
		local scrollFrame = frame.ScrollFrame
		local scrollChild = scrollFrame.ScrollChild
		local item = CreateFrame("Button", name.."ScrollChildItem"..i, scrollChild)
		item.Index = i
		
		if i == 1 then
			item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT")
		else
			item:SetPoint("TOPLEFT", scrollChild.Items[i-1], "BOTTOMLEFT", 0, -5)
		end
		
		item:SetWidth(290)
		item:SetHeight(32)
		
		-- Backdrop
		item.Backdrop = Dejunk_CreateColorTexture(item, "BACKGROUND", Consts.Colors.ScrollItem)
		
		-- Item icon
		item.Icon = item:CreateTexture(nil, "OVERLAY")
		item.Icon:SetPoint("LEFT", item, "LEFT", 6, 0)
		item.Icon:SetWidth(25)
		item.Icon:SetHeight(25)
		
		-- Item name text
		item.Text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		item.Text:SetPoint("LEFT", item.Icon, "RIGHT", 5, 0)
		item.Text:SetWidth(240)
		item.Text:SetHeight(1)
		item.Text:SetJustifyH("LEFT")
		
		-- Scripts
		item:SetScript("OnEnter", function(self)
			self.Backdrop:SetColorTexture(unpack(Consts.Colors.ScrollItemHi))
		end)
		
		item:SetScript("OnLeave", function(self)
			self.Backdrop:SetColorTexture(unpack(Consts.Colors.ScrollItem))
		end)
		
		item:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		
		item:SetScript("OnClick", function(self, button, down)
			if button == "LeftButton" then
				Dejunk_AddItemToScrollFrame(scrollFrame)
			elseif button == "RightButton" then
				Dejunk_RemoveItemFromScrollFrame(scrollFrame, item.Index)
			end
		end)
		
		item:Hide()
		scrollChild.Items[i] = item
	end
	
	return frame
end

function Dejunk_CreateCheckButton(name, parent, point, relativeFrame, relativePoint, offsetX, offsetY, size, font, text, color)
	local button = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
	button:SetPoint(point, relativeFrame, relativePoint, offsetX, offsetY)
	button:SetHeight(size)
	button:SetWidth(size)
	
	button.Text = parent:CreateFontString(nil, "OVERLAY", font)
	button.Text:SetPoint("LEFT", button, "RIGHT", 0, 0)
	button.Text:SetTextColor(unpack(color))
	button.Text:SetText(text)
	
	return button
end

function Dejunk_CreateColorTexture(frame, level, color)
	local texture = frame:CreateTexture(nil, level)
	texture:SetAllPoints()
	
	if color then
		texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
	else
		texture:SetColorTexture(1, 0, 1, 1) -- Magenta = FIX IT :)
	end
	
	return texture
end

function Dejunk_GenericGameTooltipOnEnter(self, anchor, header, ...)
	GameTooltip:SetOwner(self, anchor)
	GameTooltip:SetText(header, 1.0, 0.82, 0)
	
	for k, v in ipairs({...}) do
		GameTooltip:AddLine(v, 1, 1, 1, true)
	end
	
	GameTooltip:Show()
end

--[[
//*******************************************************************
//  				 Dejunk Frame Handler Functions
//*******************************************************************
--]]

function Dejunk_ShowOptionsFrame()
	if DejunkOptionsFrame:IsVisible() then
		DejunkOptionsFrame:Hide()
	else
		DejunkOptionsFrame:Show()
	end
end

function Dejunk_OnVerticalScroll(self, value)
	-- Clamp scroll value to min/max
	local minVal, maxVal = self:GetMinMaxValues()
	if value < minVal then value = minVal
	elseif value > maxVal then value = maxVal end
	
	self:SetValue(value)
	
	local parent = self:GetParent()
	parent.Offset = floor(value + 0.5)
	
	Dejunk_UpdateScrollFrame(parent)
end

function Dejunk_UpdateScrollFrame(self)
	if #self.ItemData > 0 then
		self.ScrollChild:Show()
		
		for i = 1, #self.ScrollChild.Items do
			local item = self.ScrollChild.Items[i]
			
			if item then
				local index = self.Offset + i
				local itemData = self.ItemData[index]
				
				if itemData then
					item.Icon:SetTexture(itemData.Texture)
					item.Text:SetText(itemData.ItemLink)
					--item.Text:SetTextColor(unpack(itemData.Color))
					--item.Text:SetText(format("[%s]", itemData.Name))
					
					item:Show()
				else
					item:Hide()
				end
			end
		end
	else
		self.ScrollChild:Hide()
	end
	
	-- Update ScrollBar values
	local maxVal = #self.ItemData - self.ItemsToDisplay
	if maxVal > 0 then
		self.ScrollBar:Show()
		self.ScrollBar:SetMinMaxValues(0, maxVal)
	else
		self.ScrollBar:SetMinMaxValues(0, 0)
		self.ScrollBar:Hide()
	end
end

function Dejunk_ScrollToIndex(self, index)
	if index < 1 then return end
	
	local _, maxVal = self:GetMinMaxValues()
	local parent = self:GetParent()
	local value = index - 1 -- scrollbar values range from 0 to max
	
	local currentValue = self:GetValue()
	local currentValueEnd = currentValue + parent.ItemsToDisplay
	
	-- If the item can be seen from this position, don't scroll.
	if value >= currentValue and value < currentValueEnd then return end
	
	if value > maxVal then
		Dejunk_OnVerticalScroll(self, maxVal)
	else
		Dejunk_OnVerticalScroll(self, value)
	end
end

function Dejunk_ScrollFrameItemIndexByItemID(self, itemID)
	for i, v in ipairs(self.ItemData) do
		if v.ItemID == itemID then
			return i
		end
	end
	
	return nil
end

function Dejunk_CreateItem(itemID, itemLink)
	local item = nil
	
	local name, _, quality, _, _, _, _, _, _, texture, price = GetItemInfo(itemLink)
	
	if name and quality and texture and price then
		item = {}
		item.Name = name
		item.Quality = quality
		item.Texture = texture
		item.ItemID = itemID
		item.ItemLink = itemLink
		item.CanBeSold = Dejunk_ItemCanBeDejunked(price, quality)
		
		local r, g, b = GetItemQualityColor(quality)
		if r and g and b then
			item.Color = {r, g, b}
		else
			item.Color = {0, 0, 0}
		end
	end
	
	return item
end

function Dejunk_AddItemToScrollFrame(self)
	if not CursorHasItem() then return end
	
	local infoType, itemID, itemLink = GetCursorInfo()
	
	ClearCursor()
	
	if infoType ~= "item" then return end
	
	local item = Dejunk_CreateItem(itemID, itemLink)
	if not item then return end
	
	if not item.CanBeSold then
		Dejunk_Print(format(L.ITEM_CANNOT_BE_SOLD, itemLink))
		return
	end
	
	-- Get other scroll frame for comparisons (remove item from other frame)
	local otherFrame = nil
	local otherFrameName = nil
	local frameName = nil
	
	if find(self:GetName(), "Inclusions") then
		frameName = Consts.Text.InclusionsColored
		otherFrame = DejunkOptionsFrame.ExclusionsFrame.ScrollFrame
		otherFrameName = Consts.Text.ExclusionsColored
	else
		frameName = Consts.Text.ExclusionsColored
		otherFrame = DejunkOptionsFrame.InclusionsFrame.ScrollFrame
		otherFrameName = Consts.Text.InclusionsColored
	end
	
	-- Make sure item isn't already present in the frame
	local alreadyExists, alreadyIndex = Dejunk_ScrollFrameHasItem(self, itemID)
	if alreadyExists then
		Dejunk_Print(format(L.ITEM_ALREADY_ON_LIST, itemLink, frameName))
		Dejunk_ScrollToIndex(self.ScrollBar, alreadyIndex)
		return
	end
	
	-- Remove the item from the other frame if it exists
	local otherExists, otherIndex = Dejunk_ScrollFrameHasItem(otherFrame, itemID)
	if otherExists then
		Dejunk_RemoveItemFromScrollFrameByIndex(otherFrame, otherIndex)
	end
	
	-- Add the item to the frame and update
	self.ItemData[#self.ItemData+1] = item
	
	Dejunk_Print(format(L.ADDED_ITEM_TO_LIST, itemLink, frameName))
	
	Dejunk_SortScrollFrameItems(self)
	Dejunk_UpdateScrollFrame(self)
	
	if #self.ItemData > self.ItemsToDisplay then
		local _, index = Dejunk_ScrollFrameHasItem(self, itemID)
		Dejunk_ScrollToIndex(self.ScrollBar, index)
	end
end

function Dejunk_RemoveItemFromScrollFrame(self, frameNum)
	-- frameNum = 1 up to self.ItemsToDisplay
	local index = frameNum + self.Offset
	Dejunk_RemoveItemFromScrollFrameByIndex(self, index)
end

function Dejunk_RemoveItemFromScrollFrameByIndex(self, index)
	local item = self.ItemData[index]
	
	if item then
		remove(self.ItemData, index)
		
		local frameName = nil
		
		if find(self:GetName(), "Inclusions") then
			frameName = Consts.Text.InclusionsColored
		else
			frameName = Consts.Text.ExclusionsColored
		end
		
		Dejunk_Print(format(L.REMOVED_ITEM_FROM_LIST, item.ItemLink, frameName))
		
		if (#self.ItemData <= self.ItemsToDisplay) and (self.ScrollBar:GetValue() > 0) then
			self.ScrollBar:SetValue(0)
		end
		
		Dejunk_UpdateScrollFrame(self)
	end
end

---- @return true/false, index/nil
function Dejunk_ScrollFrameHasItem(self, itemID)
	for k, v in pairs(self.ItemData) do
		if v.ItemID == itemID then
			return true, k
		end
	end
	
	return false, nil
end

function Dejunk_SortScrollFrameItems(self)
	if #self.ItemData <= 0 then return end
	
	-- Sort items by name if they have the same quality. Otherwise, sort by quality.
	sort(self.ItemData,
		function(a, b)
			local n = a.Quality - b.Quality
			if n == 0 then return a.Name < b.Name end
			return a.Quality < b.Quality
		end)
end

--[[
//*******************************************************************
//  		    Dejunk Option Frame Generic Functions
//*******************************************************************
--]]

function Dejunk_ResizeOptionsFrame()
	--[[
		Reposition Sell All check button options.
		Currently, Sell All text is the anchor point for all quality buttons.
	--]]
	DejunkOptionsFrame.SellAll:ClearAllPoints()
	DejunkOptionsFrame.SellAllBackdrop:ClearAllPoints()
	
	DejunkOptionsFrame.SellAllBackdrop:SetPoint("TOPLEFT", DejunkOptionsFrame.SellAll, "TOPLEFT", 0, 0)
	DejunkOptionsFrame.SellAllBackdrop:SetPoint("BOTTOMRIGHT", DejunkOptionsFrame.SellEpic.Text, "BOTTOMRIGHT", 0, 0)
	
	local sellAllWidth = DejunkOptionsFrame.SellAllBackdrop:GetWidth()
	local sellAllHeight = DejunkOptionsFrame.SellAllBackdrop:GetHeight()
	local sellAllSpacing = DejunkOptionsFrame.SellAll.Spacing
	
	DejunkOptionsFrame.SellAllBackdrop:SetWidth(sellAllWidth)
	DejunkOptionsFrame.SellAllBackdrop:SetHeight(sellAllHeight)
	DejunkOptionsFrame.SellAllBackdrop:ClearAllPoints()
	DejunkOptionsFrame.SellAllBackdrop:SetPoint("TOP", DejunkOptionsFrame.OptionsAreaTexture, "TOP", 0, -8)
	
	DejunkOptionsFrame.SellAll:SetPoint("LEFT", DejunkOptionsFrame.SellAllBackdrop, "LEFT", 0, 0)
	
	-- Resize options frame if required
	local optionsAreaWidth = DejunkOptionsFrame.OptionsAreaTexture:GetWidth()
	local optionsAreaHeight = DejunkOptionsFrame.OptionsAreaTexture:GetWidth()
	local optionsAreaSpacing = DejunkOptionsFrame.OptionsAreaTexture.Spacing
	
	if sellAllWidth >= (optionsAreaWidth - optionsAreaSpacing) then
		DejunkOptionsFrame:SetWidth(sellAllWidth + sellAllSpacing + optionsAreaSpacing)
	end
	
	--[[
		Reposition other check button options.
		Currently, Auto Sell is the anchor point for all other buttons.
	--]]
	DejunkOptionsFrame.AutoSell:ClearAllPoints()
	DejunkOptionsFrame.AutoSellBackdrop:ClearAllPoints()
	
	DejunkOptionsFrame.AutoSellBackdrop:SetPoint("TOPLEFT", DejunkOptionsFrame.AutoSell, "TOPLEFT", 0, 0)
	DejunkOptionsFrame.AutoSellBackdrop:SetPoint("BOTTOMRIGHT", DejunkOptionsFrame.SilentMode.Text, "BOTTOMRIGHT", 0, 0)
	
	local autoSellWidth = DejunkOptionsFrame.AutoSellBackdrop:GetWidth()
	local autoSellHeight = DejunkOptionsFrame.AutoSellBackdrop:GetHeight()
	local autoSellSpacing = DejunkOptionsFrame.AutoSell.Spacing
	
	DejunkOptionsFrame.AutoSellBackdrop:SetWidth(autoSellWidth)
	DejunkOptionsFrame.AutoSellBackdrop:SetHeight(autoSellHeight)
	DejunkOptionsFrame.AutoSellBackdrop:ClearAllPoints()
	DejunkOptionsFrame.AutoSellBackdrop:SetPoint("BOTTOM", DejunkOptionsFrame.OptionsAreaTexture, "BOTTOM", 0, 9)
	
	DejunkOptionsFrame.AutoSell:ClearAllPoints()
	DejunkOptionsFrame.AutoSell:SetPoint("LEFT", DejunkOptionsFrame.AutoSellBackdrop, "LEFT", 0, 0)
	
	-- Resize options frame if required
	optionsAreaWidth = DejunkOptionsFrame.OptionsAreaTexture:GetWidth()
	optionsAreaHeight = DejunkOptionsFrame.OptionsAreaTexture:GetWidth()
	
	if autoSellWidth >= (optionsAreaWidth - optionsAreaSpacing) then
		DejunkOptionsFrame:SetWidth(autoSellWidth + autoSellSpacing + optionsAreaSpacing)
	end
end

function Dejunk_UpdateOptionSettings()
	-- Character Specific
	DejunkOptionsFrame.CharacterSpecific:SetChecked(not DejunkPerChar.UseGlobal)

	-- Sell All
	DejunkOptionsFrame.SellPoor:SetChecked(DejunkDB.SellPoor)
	DejunkOptionsFrame.SellCommon:SetChecked(DejunkDB.SellCommon)
	DejunkOptionsFrame.SellUncommon:SetChecked(DejunkDB.SellUncommon)
	DejunkOptionsFrame.SellRare:SetChecked(DejunkDB.SellRare)
	DejunkOptionsFrame.SellEpic:SetChecked(DejunkDB.SellEpic)

	-- Other options
	DejunkOptionsFrame.AutoSell:SetChecked(DejunkDB.AutoSell)
	DejunkOptionsFrame.AutoRepair:SetChecked(DejunkDB.AutoRepair)
	DejunkOptionsFrame.SafeMode:SetChecked(DejunkDB.SafeMode)
	DejunkOptionsFrame.SilentMode:SetChecked(DejunkDB.SilentMode)

	-- Inclusions
	local scrollFrame = DejunkOptionsFrame.InclusionsFrame.ScrollFrame
	scrollFrame.ItemData = DejunkDB.Inclusions
	Dejunk_OnVerticalScroll(scrollFrame.ScrollBar, 0)

	-- Exclusions
	scrollFrame = DejunkOptionsFrame.ExclusionsFrame.ScrollFrame
	scrollFrame.ItemData = DejunkDB.Exclusions
	Dejunk_OnVerticalScroll(scrollFrame.ScrollBar, 0)
end

function Dejunk_LockOptionSettings()
	-- Character Specific
	DejunkOptionsFrame.CharacterSpecific:Disable()

	-- Sell All
	DejunkOptionsFrame.SellPoor:Disable()
	DejunkOptionsFrame.SellCommon:Disable()
	DejunkOptionsFrame.SellUncommon:Disable()
	DejunkOptionsFrame.SellRare:Disable()
	DejunkOptionsFrame.SellEpic:Disable()

	-- Other options
	DejunkOptionsFrame.AutoSell:Disable()
	DejunkOptionsFrame.AutoRepair:Disable()
	DejunkOptionsFrame.SafeMode:Disable()
	DejunkOptionsFrame.SilentMode:Disable()
	
	DejunkOptionsFrame.InclusionsFrame:Hide()
	DejunkOptionsFrame.ExclusionsFrame:Hide()
end

function Dejunk_UnlockOptionSettings()
	-- Character Specific
	DejunkOptionsFrame.CharacterSpecific:Enable()

	-- Sell All
	DejunkOptionsFrame.SellPoor:Enable()
	DejunkOptionsFrame.SellCommon:Enable()
	DejunkOptionsFrame.SellUncommon:Enable()
	DejunkOptionsFrame.SellRare:Enable()
	DejunkOptionsFrame.SellEpic:Enable()

	-- Other options
	DejunkOptionsFrame.AutoSell:Enable()
	DejunkOptionsFrame.AutoRepair:Enable()
	DejunkOptionsFrame.SafeMode:Enable()
	DejunkOptionsFrame.SilentMode:Enable()
	
	DejunkOptionsFrame.InclusionsFrame:Show()
	DejunkOptionsFrame.ExclusionsFrame:Show()
end