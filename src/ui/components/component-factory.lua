local Addon = select(2, ...) ---@type Addon

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

--- Width of the strip on the left edge of a card.
ComponentFactory.CARD_ACCENT_WIDTH = 3

--- Width of each icon button on a card.
ComponentFactory.CARD_BUTTON_WIDTH = 32
