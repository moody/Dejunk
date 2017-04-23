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

-- Dejunk_Core: contains all of dejunk's core functionality.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Core = DJ.Core

local Colors = DJ.Colors
local DejunkDB = DJ.DejunkDB
local ListManager = DJ.ListManager
local Tools = DJ.Tools
local BaseFrame = DJ.BaseFrame
local BasicChildFrame = DJ.BasicChildFrame
local TransportChildFrame = DJ.TransportChildFrame

-- Variables
Core.Debugging = false

--[[
//*******************************************************************
//                            Core Frame
//*******************************************************************
--]]

local coreFrame = CreateFrame("Frame", AddonName.."CoreFrame")

coreFrame:SetScript("OnEvent", function(frame, event, ...)
  if (event == "ADDON_LOADED") then
    if (... == AddonName) then
      frame:UnregisterEvent(event)
      Core:Initialize()
    end
  end
end)

coreFrame:RegisterEvent("ADDON_LOADED")

--[[
//*******************************************************************
//                      Core General Functions
//*******************************************************************
--]]

-- Initializes all modules.
function Core:Initialize()
  DejunkDB:Initialize()
  Colors:Initialize()
  ListManager:Initialize()
  DJ.MerchantButton:Initialize()
  DJ.MinimapIcon:Initialize()

  BaseFrame:Initialize()
  BaseFrame:SetCurrentChild(BasicChildFrame)

  -- Setup slash command
	SLASH_DEJUNK1 = "/dejunk"
	SlashCmdList["DEJUNK"] = function (msg, editBox)
		BaseFrame:Toggle() end
end

-- Prints a formatted message ("[Dejunk] msg").
-- @param msg - the message to print
function Core:Print(msg)
  if DejunkDB.SV.SilentMode then return end

  local title = Tools:GetColorString("[Dejunk]",
    Colors:GetColor(Colors.LabelText))

  print(format("%s %s", title, msg))
end

-- Prints a debug message ("[Dejunk][Debug] msg").
-- @param msg - the debug message to print
function Core:Debug(msg)
  if not self.Debugging then return end

  local title = Tools:GetColorString("[DJ-Debug]",
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
  BaseFrame:Toggle()
end

-- Enables Dejunk's GUI.
function Core:EnableGUI()
  BaseFrame:Enable()
end

-- Disables Dejunk's GUI.
function Core:DisableGUI()
  BaseFrame:Disable()
end

-- Switches between global and character specific settings.
function Core:ToggleCharacterSpecificSettings()
  DejunkPerChar.UseGlobal = not DejunkPerChar.UseGlobal
  DejunkDB:Update()
  ListManager:Update()

  if (BaseFrame:GetCurrentChild() ~= BasicChildFrame) then
    BaseFrame:SetCurrentChild(BasicChildFrame) end

  BaseFrame:Refresh()
end

-- Sets the BaseFrame's child to BasicChildFrame.
function Core:ShowBasicChild()
  previousChild = nil
  BaseFrame:SetCurrentChild(BasicChildFrame)
end

-- Sets the BaseFrame's child to TransportChildFrame.
-- @param listName - the name of the list used for transport operations
-- @param transportType - the type of transport operations to perform
function Core:ShowTransportChild(listName, transportType)
  previousChild = BaseFrame:GetCurrentChild()

  BaseFrame:SetCurrentChild(TransportChildFrame, function()
    TransportChildFrame:SetData(listName, transportType)
  end)
end

-- Sets the BaseFrame's child to the previously displayed child.
function Core:ShowPreviousChild()
  if not previousChild then return end
  BaseFrame:SetCurrentChild(previousChild)
end
