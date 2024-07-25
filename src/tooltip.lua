local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Tooltip : GameTooltip
local Tooltip = Addon:GetModule("Tooltip")

local cache = {}

-- Wrap `GameTooltip`.
setmetatable(Tooltip, {
  __index = function(_, k)
    local v = GameTooltip[k]
    if type(v) == "function" then
      if cache[k] == nil then
        cache[k] = function(_, ...) v(GameTooltip, ...) end
      end
      return cache[k]
    end
    return v
  end
})

--- @param text string
function Tooltip:SetText(text)
  GameTooltip:SetText(Colors.White(text))
end

--- @param text string
function Tooltip:AddLine(text)
  GameTooltip:AddLine(Colors.Gold(text), nil, nil, nil, true)
end

--- @param leftText string
--- @param rightText string
function Tooltip:AddDoubleLine(leftText, rightText)
  GameTooltip:AddDoubleLine(Colors.Blue(leftText), Colors.White(rightText))
end
