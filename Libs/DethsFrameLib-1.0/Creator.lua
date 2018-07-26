-- Creator: contains simple create functions for UIObjects (frames, buttons, textures, etc.).

-- Lib
local MAJOR = "DethsFrameLib-1.0"
local DFL = LibStub:GetLibrary(MAJOR)
if DFL.ALREADY_LOADED then return end

local Creator = DFL.Creator

-- Wow upvalues
local CreateFrame, UIParent = CreateFrame, UIParent

-- ============================================================================
-- Frame
-- ============================================================================

do
  local count = 0

  -- Returns a frame.
  -- @param parent - the parent frame
  -- @return - a basic frame
  function Creator:CreateFrame(parent)
    count = (count + 1)

    local name = (MAJOR.."Frame"..count)
    local frame = CreateFrame("Frame", name, parent or UIParent)
    frame:Show()
    
    return frame
  end
end

-- ============================================================================
-- Button
-- ============================================================================

do
  local count = 0

  -- Returns a button.
  -- @param parent - the parent of the button
  -- @return - a basic button
  function Creator:CreateButton(parent)
    count = (count + 1)

    local name = (MAJOR.."Button"..count)
    local button = CreateFrame("Button", name, parent)
    button:RegisterForClicks("LeftButtonUp")
    button:Show()
    
    return button
  end
end

-- ============================================================================
-- Check Button
-- ============================================================================

do
  local count = 0
  local checkedTexture = "Interface\\Buttons\\UI-CheckBox-Check"
  local disabledTexture = "Interface\\Buttons\\UI-CheckBox-Check-Disabled"  

  -- Returns a check button.
  -- @param parent - the parent of the check button
  -- @return - a basic check button
  function Creator:CreateCheckButton(parent)
    count = (count + 1)

    local name = (MAJOR.."CheckButton"..count)
    local checkButton = CreateFrame("CheckButton", name, parent)
    checkButton:SetCheckedTexture(checkedTexture)
    checkButton:SetDisabledCheckedTexture(disabledTexture)
    checkButton:Show()

    return checkButton
  end
end

-- ============================================================================
-- Texture
-- ============================================================================

do
  local count = 0

  -- Returns a texture.
  -- @param parent - the parent frame
  -- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.)
  -- @return - a basic texture
  function Creator:CreateTexture(parent, layer)
    count = (count + 1)

    local name = (MAJOR.."Texture"..count)
    texture = parent:CreateTexture(name, (layer or "BACKGROUND"))

    texture:SetAllPoints()
    texture:Show()

    return texture
  end
end

-- ============================================================================
-- Font String
-- ============================================================================

do
  local count = 0

  -- Returns a font string.
  -- @param parent - the parent frame
  -- @param text - the initial text [optional]
  -- @param font - the font style to inherit [optional]
  -- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
  -- @return - a basic font string
  function Creator:CreateFontString(parent, text, font, layer)
    count = (count + 1)

    local name = (MAJOR.."FontString"..count)
    fontString = parent:CreateFontString(name, (layer or "OVERLAY"), (font or DFL.Fonts.Normal))
    fontString:SetText(text)
    fontString:Show()

    return fontString
  end
end

-- ============================================================================
-- Scroll Frame
-- ============================================================================

do
  local count = 0

  -- Returns a scroll frame.
  -- @param parent - the parent frame
  -- @return - a basic scroll frame
  function Creator:CreateScrollFrame(parent)
    count = (count + 1)

    local name = (MAJOR.."ScrollFrame"..count)
    local scrollFrame = CreateFrame("ScrollFrame", name, parent)
    scrollFrame:SetClipsChildren(true)
    scrollFrame:Show()

    return scrollFrame
  end
end

-- ============================================================================
-- Slider
-- ============================================================================

do
  local count = 0

  -- Returns a slider.
  -- @param parent - the parent frame
  -- @return - a basic slider
  function Creator:CreateSlider(parent)
    count = (count + 1)

    local name = (MAJOR.."Slider"..count)
    local slider = CreateFrame("Slider", name, parent)
    slider:SetObeyStepOnDrag(true)
    slider:SetMinMaxValues(0, 0)
    slider:SetValue(0)
    slider:Show()

    return slider
  end
end

-- ============================================================================
-- Edit Box
-- ============================================================================

do
  local count = 0
  local EditBox_ClearFocus = EditBox_ClearFocus

  -- Returns an edit box.
  -- @param parent - the parent frame
  -- @param maxLetters - the maximum amount of characters [optional]
  -- @param numeric - whether or not the edit box only accepts numeric input [optional]
  -- @param font - the font style for the edit box to inherit [optional]
  -- @return - a basic edit box
  function Creator:CreateEditBox(parent, maxLetters, numeric, font)
    count = (count + 1)

    local name = (MAJOR.."EditBox"..count)
    local editBox = CreateFrame("EditBox", name, parent)
    editBox:SetScript("OnEscapePressed", EditBox_ClearFocus)
    editBox:SetFontObject(font or DFL.Fonts.Normal)
    editBox:SetMaxLetters(maxLetters or 0)
    editBox:SetNumeric(numeric)
    editBox:SetMultiLine(false)
    editBox:SetAutoFocus(false)
    editBox:ClearFocus()

    editBox:Show()

    return editBox
  end
end
