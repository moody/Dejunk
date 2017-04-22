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

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Test = DJ.Test

local Colors = DJ.Colors
local ListManager = DJ.ListManager
local FramePooler = DJ.FramePooler

local BaseFrame = DJ.BaseFrame

--[[
//*******************************************************************
//  					    			   Slash Commands
//*******************************************************************
--]]

SLASH_DEJUNKTEST1 = "/dejunktest"
SlashCmdList["DEJUNKTEST"] = function(msg, editBox)
  if msg == "stats" then
    Test:Stats()

  -- BaseFrame tests
  elseif msg == "baseframe_toggle" then
    BaseFrameTest:Toggle()
  elseif msg == "baseframe_init" then
    BaseFrame:Initialize()
  elseif msg == "baseframe_deinit" then
    BaseFrame:Deinitialize()
  elseif msg == "baseframe_width" then
    BaseFrame:SetWidth(800)
  elseif msg == "baseframe_child" then
    BaseFrame:SetCurrentChild(DJ.BasicChildFrame)
  elseif msg == "baseframe_enable" then
    BaseFrame:Enable()
  elseif msg == "baseframe_disable" then
    BaseFrame:Disable()
  elseif msg == "color" then
    Colors:SetColorScheme("Redscale")
    BaseFrame:Refresh()
  elseif msg == "recolor" then
    Colors:SetColorScheme("Default")
    BaseFrame:Refresh()

  -- ListManager tests
  elseif msg == "lm_add_in" then
    for i=1, 2000 do
      ListManager:AddToList("Inclusions", i)
    end
  elseif msg == "lm_rem_in" then
    for i=1, 2000 do
      ListManager:RemoveFromList("Inclusions", i)
    end
  elseif msg == "lm_add_ex" then
    for i=10000, 20000 do
      ListManager:AddToList("Exclusions", i)
    end
  elseif msg == "lm_rem_ex" then
    for i=10000, 20000 do
      ListManager:RemoveFromList("Exclusions", i)
    end
  elseif msg == "lm_des_in" then
    ListManager:DestroyList("Inclusions")
  elseif msg == "lm_des_ex" then
    ListManager:DestroyList("Exclusions")
  end
end

--[[
//*******************************************************************
//  					    			      Test Functions
//*******************************************************************
--]]

function Test:Stats()
  local printColor = function(s, c)
    print(DJ.Tools:GetColorString(s, c))
  end

  local printStats = function(data)
    local name, count, pool = unpack(data)
    printColor(name.." created: "..count, Colors:GetColor(Colors.LabelText))
    printColor(name.." in pool: "..#pool, Colors:GetColor(Colors.Exclusions))
    printColor(name.." in play: "..(count - #pool), Colors:GetColor(Colors.Inclusions))
    print("")
  end

  print("")
  printColor("DEJUNK TEST STATS:", {1, 1, 1})
  print("")

  printStats({"Frames", FramePooler.FrameCount, FramePooler.FramePool})
  printStats({"Buttons", FramePooler.ButtonCount, FramePooler.ButtonPool})
  printStats({"CheckButtons", FramePooler.CheckButtonCount, FramePooler.CheckButtonPool})
  printStats({"Textures", FramePooler.TextureCount, FramePooler.TexturePool})
  printStats({"FontStrings", FramePooler.FontStringCount, FramePooler.FontStringPool})
  printStats({"ScrollFrames", FramePooler.ScrollFrameCount, FramePooler.ScrollFramePool})
  printStats({"Sliders", FramePooler.SliderCount, FramePooler.SliderPool})
  printStats({"EditBoxes", FramePooler.EditBoxCount, FramePooler.EditBoxPool})

  printColor("END DEJUNK TEST STATS.", {1, 1, 1})
  print("")
end
