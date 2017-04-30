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

-- Dejunk
local FrameFader = DJ.FrameFader

-- Variables
local FADE_DELAY = 0.025
local fadeInterval = 0


--[[
//*******************************************************************
//                            Fader Frame
//*******************************************************************
--]]

local faderFrame = CreateFrame("Frame", AddonName.."FaderFrame")
faderFrame.Scripts = {} -- Currently active scripts
faderFrame.ScriptQueue = {} -- Queued scripts

function faderFrame:OnUpdate(elapsed)
  -- Pull scripts from queue
  for i, script in pairs(self.ScriptQueue) do
    self.Scripts[#self.Scripts+1] = script
    self.ScriptQueue[i] = nil
  end

  fadeInterval = (fadeInterval + elapsed)
  if (fadeInterval >= FADE_DELAY) then
    fadeInterval = 0

    -- Update scripts
    for i, script in ipairs(self.Scripts) do
      if script() then self.Scripts[i] = nil end
    end
  end
end

faderFrame:SetScript("OnUpdate", faderFrame.OnUpdate)

--[[
//*******************************************************************
//  					    			    Frame Fading Functions
//*******************************************************************
--]]

-- Fades in a frame.
-- @param frame - the frame to fade
-- @param fadeTime - the fade time in seconds
-- @param callback - the function to call once fading is complete
function FrameFader:FadeIn(frame, fadeTime, callback)
  assert((type(fadeTime) == "number") and (fadeTime > 0), "fadeTime must be greater than zero")

  local alpha = frame:GetAlpha()
  if alpha >= 1 then if callback then callback() end return end

  local fadeAmount = (FADE_DELAY / fadeTime)

  -- Create script
  local script = function()
    alpha = (alpha + fadeAmount)
    frame:SetAlpha(alpha)

    if alpha >= 0.95 then
      frame:SetAlpha(1)
      if callback then callback() end
      return true -- Done
    end

    return false -- Not done
  end

  -- Add script to queue
  faderFrame.ScriptQueue[#faderFrame.ScriptQueue+1] = script
end

-- Fades out a frame.
-- @param frame - the frame to fade
-- @param fadeTime - the fade time in seconds
-- @param callback - the function to call once fading is complete
function FrameFader:FadeOut(frame, fadeTime, callback)
  assert((type(fadeTime) == "number") and (fadeTime > 0), "fadeTime must be greater than zero")

  local alpha = frame:GetAlpha()
  if alpha <= 0 then if callback then callback() end return end

  local fadeAmount = (FADE_DELAY / fadeTime)

  -- Create script
  local script = function()
    alpha = (alpha - fadeAmount)
    frame:SetAlpha(alpha)

    if alpha <= 0.05 then
      frame:SetAlpha(0)
      if callback then callback() end
      return true -- Done
    end

    return false -- Not done
  end

  -- Add script to queue
  faderFrame.ScriptQueue[#faderFrame.ScriptQueue+1] = script
end
