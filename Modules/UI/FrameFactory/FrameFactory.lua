-- FrameFactory: contains functions that return UIObjects tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

-- ============================================================================
--                             UI Table Functions
-- ============================================================================

-- Enables a table of objects created by FrameFactory.
-- @param ui - the table of objects to be enabled
function FrameFactory:EnableUI(ui)
  for k, v in pairs(ui) do
    local func = ("Enable"..tostring(v.FF_ObjectType))

    if self[func] then
      self[func](self, v)
    elseif v.SetEnabled then
      v:SetEnabled(true)
    end
  end
end

-- Disables a table of objects created by FrameFactory.
-- @param ui - the table of objects to be disabled
function FrameFactory:DisableUI(ui)
  for k, v in pairs(ui) do
    local func = ("Disable"..tostring(v.FF_ObjectType))

    if self[func] then
      self[func](self, v)
    elseif v.SetEnabled then
      v:SetEnabled(false)
    end
  end
end

-- Refreshes a table of objects created by FrameFactory.
-- @param ui - the table of objects to be refreshed
function FrameFactory:RefreshUI(ui)
  for k, v in pairs(ui) do v:Refresh() end
end
