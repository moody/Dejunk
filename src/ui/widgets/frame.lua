local _, Addon = ...
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates a basic frame with a backdrop.

  options = {
    name? = string,
    frameType? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number
  }
]]
function Widgets:Frame(options)
  local frame = CreateFrame(options.frameType or "Frame", options.name, options.parent or UIParent)
  frame:SetClipsChildren(true)

  -- Backdrop.
  if not frame.SetBackdrop then
    Mixin(frame, BackdropTemplateMixin)
  end
  frame:SetBackdrop(self.BORDER_BACKDROP)
  frame:SetBackdropColor(0, 0, 0, 0.75)
  frame:SetBackdropBorderColor(0, 0, 0, 1)

  -- Options.
  if options.width then frame:SetWidth(options.width) end
  if options.height then frame:SetHeight(options.height) end
  if options.points then
    for _, point in ipairs(options.points) do
      frame:SetPoint(SafeUnpack(point))
    end
  end

  return frame
end
