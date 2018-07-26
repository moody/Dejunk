local MAJOR, MINOR = "DethsFrameLib-1.0", 1

-- LibStub
local DFL, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not DFL then
  LibStub:GetLibrary(MAJOR).ALREADY_LOADED = true
  return
end

DFL.ALREADY_LOADED = false

-- Upvalues
local abs, assert, error, floor, nop, pairs, ipairs, tonumber, tostring, type =
      abs, assert, error, floor, nop, pairs, ipairs, tonumber, tostring, type

DFL.Creator = {}

-- ============================================================================
-- Consts Tables
-- ============================================================================

-- Alignments, Points
DFL.Alignments = {
  -- Top
  TOPLEFT = "TOPLEFT",
  TOP = "TOP",
  TOPRIGHT = "TOPRIGHT",
  -- Middle
  LEFT = "LEFT",
  CENTER = "CENTER",
  RIGHT = "RIGHT",
  -- Bottom
  BOTTOMLEFT = "BOTTOMLEFT",
  BOTTOM = "BOTTOM",
  BOTTOMRIGHT = "BOTTOMRIGHT"
}
DFL.Points = DFL.Alignments

-- Anchors
DFL.Anchors = {
  NONE = "ANCHOR_NONE",
  CURSOR = "ANCHOR_CURSOR",
  PRESERVE = "ANCHOR_PRESERVE",
  -- Top
  TOPLEFT = "ANCHOR_TOPLEFT",
  TOP = "ANCHOR_TOP",
  TOPRIGHT = "ANCHOR_TOPRIGHT",
  -- Middle
  LEFT = "ANCHOR_LEFT",
  RIGHT = "ANCHOR_RIGHT",
  -- Bottom
  BOTTOMLEFT = "ANCHOR_BOTTOMLEFT",
  BOTTOM = "ANCHOR_BOTTOM",
  BOTTOMRIGHT = "ANCHOR_BOTTOMRIGHT"
}

-- Colors
DFL.Colors = {
  None = {0, 0, 0, 0},
  Black = {0, 0, 0, 1},
  White = {1, 1, 1, 1},

  Area = {0.1, 0.1, 0.2, 0.5},
  Button   = {0.05, 0.05, 0.15, 1},
  ButtonHi = {0.15, 0.15, 0.3, 1},
  Frame = {0, 0, 0.05, 0.95},
  Text = {0.35, 0.35, 0.6, 1},
  Thumb = {0.1, 0.1, 0.2, 1}
}

-- Directions
DFL.Directions = {
  UP = "UP",
  DOWN = "DOWN",
  LEFT = "LEFT",
  RIGHT = "RIGHT"
}

-- Fonts
DFL.Fonts = {
  -- GameFont
  Huge = "GameFontNormalHuge",
  HugeOutline = "GameFontNormalHugeOutline",
  Large = "GameFontNormalLarge",
  LargeOutline = "GameFontNormalLargeOutline",
  Normal = "GameFontNormal",
  NormalOutline = "GameFontNormalOutline",
  Medium = "GameFontNormalMed1",
  Small = "GameFontNormalSmall",
  Tiny = "GameFontNormalTiny",
  -- NumberFont
  Number = "NumberFontNormal",
  NumberHuge = "NumberFontNormalHuge",
  NumberSmall = "NumberFontNormalSmall",
}

-- Layouts
DFL.Layouts = {
  -- Layouts are used by DFL.Frame when resizing and positioning children.
  
  -- FILL: with 3 children, |-11-2-333-------| becomes |-1111-2222-3333-|
  FILL = "FILL",
  -- FLEX: with 3 children, |-1-2-3-----| becomes |-1---2---3-|
  FLEX = "FLEX",
  -- FLEX_EQUAL: with 3 children, |-1-22-333------| becomes |-111--222--333-|
  FLEX_EQUAL = "FLEX_EQUAL",
  -- FLOW: (Default) Children are simply positioned one by one.
  FLOW = "FLOW",
  -- FLOW_EQUAL: with 3 children, |-1-22-333-| becomes |-111-222-333-|
  FLOW_EQUAL = "FLOW_EQUAL"
}

-- Orientations
DFL.Orientations = {
  VERTICAL = "VERTICAL",
  HORIZONTAL = "HORIZONTAL"
}

-- ============================================================================
-- Tooltip Functions
-- ============================================================================

do -- ShowTooltip(), HideTooltip()
  local GameTooltip = GameTooltip

  -- Displays a generic game tooltip.
  -- @param owner - the frame the tooltip belongs to
  -- @param anchorType - the anchor type ("ANCHOR_LEFT", "ANCHOR_CURSOR", etc.)
  -- @param title - the title of the tooltip
  -- @param ... - the body lines of the tooltip
  function DFL:ShowTooltip(owner, anchorType, title, ...)
  	GameTooltip:SetOwner(owner, anchorType)
  	GameTooltip:SetText(title, 1.0, 0.82, 0)

  	for k, v in ipairs({...}) do
      -- if (type(v) == "function") then v = v() end
  		GameTooltip:AddLine(v, 1, 1, 1, true)
  	end

  	GameTooltip:Show()
  end

  -- Hides the game tooltip.
  function DFL:HideTooltip()
    GameTooltip:Hide()
  end
end

-- ============================================================================
-- UI Functions
-- ============================================================================

do -- AddBorder()
  local BACKDROP = {
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1
  }

  function DFL:AddBorder(frame, ...)
    local r, g, b = ...
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(r or 0, g or 0, b or 0)
  end

  function DFL:RemoveBorder(frame)
    frame:SetBackdrop(nil)
  end
end

do -- Measure()
  local sizer = UIParent:CreateTexture(MAJOR.."DFLSizer", "BACKGROUND")
  sizer:SetColorTexture(0, 0, 0, 0)

  -- Measures the width and height between the top-left point of the startRegion
  -- and the bottom-right point of the endRegion.
  -- @param parent - the parent frame used to create a temporary texture
  -- @param startRegion - the left-most region
  -- @param endRegion - the right-most region
  -- @param startPoint - the point on the startRegion to measure from [optional]
  -- @param endPoint - the point on the endRegion to measure to [optional]
  -- @return width - the width between the two regions
  -- @return height - the height
  function DFL:Measure(parent, startRegion, endRegion, startPoint, endPoint)
    sizer:ClearAllPoints()
    sizer:SetParent(parent)
    sizer:SetPoint(startPoint or "TOPLEFT", startRegion)
    sizer:SetPoint(endPoint or "BOTTOMRIGHT", endRegion)
    return sizer:GetWidth(), sizer:GetHeight()
  end
end

do -- Padding()
  local paddingCache = {}

  -- Returns the default padding with an optional multiplier.
  -- @param multiplier - a number to multiply padding by [optional]
  -- @return - the absolute value of default padding times the multiplier or 1.
  function DFL:Padding(multiplier)
    multiplier = tonumber(multiplier) or 1
    
    local key = tostring(multiplier)
    if not paddingCache[key] then
      paddingCache[key] = floor(abs(10 * multiplier) + 0.5)
    end

    return paddingCache[key]
  end
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Adds mixins to the specified object.
-- @param obj - the object to add mixins to
-- @param mixins - a table of values to add
function DFL:AddMixins(obj, mixins)
  for k, v in pairs(mixins) do obj[k] = v end
end

-- Removes mixins from the specified object.
-- @param obj - the object to remove mixins from
-- @param mixins - a table of values to remove
function DFL:RemoveMixins(obj, mixins)
  for k in pairs(mixins) do obj[k] = nil end
end

-- Adds scripts to the specified object.
-- @param obj - the object to add scripts to
-- @param scripts - a table of script functions to add
function DFL:AddScripts(obj, scripts)
  for k, v in pairs(scripts) do obj:SetScript(k, v) end
end

-- Removes scripts from the specified object.
-- @param obj - the object to remove scripts from
-- @param scripts - a table of script functions to remove
function DFL:RemoveScripts(obj, scripts)
  for k in pairs(scripts) do obj:SetScript(k, nil) end
end

-- Returns true if the specified object is of the specified type.
-- @param obj - the object
-- @param objType - the type to test for
function DFL:IsType(obj, objType)
  return (type(obj) == "table") and obj.GetType and (obj:GetType() == objType)
end

-- Sets the enabled or disabled alpha of the specified object.
function DFL:SetEnabledAlpha(obj, enabled)
  obj:SetAlpha(enabled and 1 or 0.3)
end

-- Returns the ParentFrame the specified object ultimately belongs to, or nil.
-- @param obj - an object ultimately belonging to a ParentFrame
function DFL:GetParentFrame(obj)
  -- If obj is a ParentFrame, return it
  if self:IsType(obj, self.ParentFrame:GetType()) then
    return obj
  else -- Otherwise, if object has a parent...
    local parent = obj.GetParent and obj:GetParent()
    if parent then return self:GetParentFrame(parent) end
  end
end

--[[
  Calls QueueResize() on the ParentFrame the specified object ultimately
  belongs to. If a ParentFrame is not found in the object's parent hierarchy,
  then this function does nothing.

  WARNING: Resizing will occur infinitely if called during an object's Resize().

  @param obj - an object ultimately belonging to a ParentFrame
]]
function DFL:ResizeParent(obj)
  local parentFrame = self:GetParentFrame(obj)
  if parentFrame then parentFrame:QueueResize() end
end

-- ============================================================================
-- NewObjectTable()
-- ============================================================================

do
  local function create(self)
    error("Create() not implemented for object type "..self:GetType())
  end

  -- Returns a new object table with default functionality.
  function DFL:NewObjectTable()
    --[[
      Using a unique table as the key instead of a generic value prevents issues
      regarding object type comparisons. If two different types of objects'
      GetType() function returned the same value, their types would be
      indistinguishable from one another. With a unique table, the type is
      guaranteed to be unique (unless someone gets stupid and codes a custom
      GetType() function).
    --]]
    local type = {}
    local getType = function() return type end
    return {
      Create = create,
      GetType = getType,
      Functions = { GetType = getType }
    }
  end
end

-- ============================================================================
-- AddDefaults()
-- ============================================================================

do
  local Defaults, objCache = {}, {}

  -- Adds default functionality to a specified object. This is required for
  -- objects to be handled properly by DFL in most cases.
  -- @param obj - the object to add defaults to
  function DFL:AddDefaults(obj)
    assert(type(obj) == "table", "obj must be a table")
    assert(not objCache[obj], "object already passed to AddDefaults()")
    objCache[obj] = true
    
    obj.SetColors = Defaults.SetColors

    -- State
    obj._defaults_isEnabled = true
    obj.IsEnabled = Defaults.IsEnabled
    obj._Enable = obj.Enable
    obj.Enable = Defaults.Enable
    obj._Disable = obj.Disable
    obj.Disable = Defaults.Disable
    obj._SetEnabled = obj.SetEnabled
    obj.SetEnabled = Defaults.SetEnabled
    obj.OnSetEnabled = Defaults.OnSetEnabled

    -- Width
    if obj.SetWidth then
      obj._defaults_minWidth = 0
      obj._SetWidth = obj.SetWidth
      obj.GetMinWidth = Defaults.GetMinWidth
      obj.SetMinWidth = Defaults.SetMinWidth
      obj.SetWidth = Defaults.SetWidth
      obj.OnSetWidth = Defaults.OnSetWidth
    end

    -- Height
    if obj.SetHeight then
      obj._defaults_minHeight = 0
      obj._SetHeight = obj.SetHeight
      obj.GetMinHeight = Defaults.GetMinHeight
      obj.SetMinHeight = Defaults.SetMinHeight
      obj.SetHeight = Defaults.SetHeight
      obj.OnSetHeight = Defaults.OnSetHeight
    end

    -- Size
    if obj.SetSize and obj._SetWidth and obj._SetHeight then
      obj._SetSize = obj.SetSize
      obj.SetSize = Defaults.SetSize
      obj.OnSetSize = Defaults.OnSetSize
    end

    obj.Refresh = Defaults.Refresh
    obj.Resize = Defaults.Resize

    return obj
  end

  -- Sets the colors of the object. Override as required.
  -- @param ... - variable number of tables containing rgba [0-1] color values
  Defaults.SetColors = nop

  -- Returns true if the object is enabled.
  function Defaults:IsEnabled() return self._defaults_isEnabled end
  -- Enables the object.
  function Defaults:Enable() self:SetEnabled(true) end
  -- Disables the object.
  function Defaults:Disable() self:SetEnabled(false) end
  -- Enables or disables the object.
  -- Implement OnSetEnabled() instead of overriding.
  function Defaults:SetEnabled(enabled)
    if (self._defaults_isEnabled == enabled) then return end
    self._defaults_isEnabled = enabled

    if self._SetEnabled then
      self:_SetEnabled(enabled)
    elseif enabled then
      if self._Enable then self:_Enable() end
    else
      if self._Disable then self:_Disable() end
    end

    self:OnSetEnabled(enabled)
  end
  Defaults.OnSetEnabled = nop

  -- Returns the minimum width of the object.
  function Defaults:GetMinWidth()
    return self._defaults_minWidth
  end

  -- Sets the minimum width of the object.
  function Defaults:SetMinWidth(width)
    -- width = floor(width + 0.5)
    -- -- Ensure width is divisible by 2 to avoid jagged placements
    -- if not (width % 2 == 0) then width = width + 1 end
    self._defaults_minWidth = (width >= 0) and
      width or error("width must be >= 0")
  end

  -- Sets the width of the object.
  -- Implement OnSetWidth(width, oldWidth) instead of overriding.
  function Defaults:SetWidth(width)
    local oldWidth = self:GetWidth()
    if (width < self._defaults_minWidth) then width = self._defaults_minWidth end
    -- width = floor(width + 0.5)
    -- -- Ensure width is divisible by 2 to avoid jagged placements
    -- if not (width % 2 == 0) then width = width + 1 end
    self:_SetWidth(width)
    self:OnSetWidth(width, oldWidth)
  end
  Defaults.OnSetWidth = nop

  -- Returns the minimum height of the object.
  function Defaults:GetMinHeight()
    return self._defaults_minHeight
  end

  -- Sets the minimum height of the object.
  function Defaults:SetMinHeight(height)
    -- height = floor(height + 0.5)
    -- -- Ensure height is divisible by 2 to avoid jagged placements
    -- if not (height % 2 == 0) then height = height + 1 end
    self._defaults_minHeight = (height >= 0) and
      height or error("height must be >= 0")
  end

  -- Sets the height of the object.
  -- Implement OnSetHeight(height, oldHeight) instead of overriding.
  function Defaults:SetHeight(height)
    local oldHeight = self:GetHeight()
    if (height < self._defaults_minHeight) then height = self._defaults_minHeight end
    -- height = floor(height + 0.5)
    -- -- Ensure height is divisible by 2 to avoid jagged placements
    -- if not (height % 2 == 0) then height = height + 1 end
    self:_SetHeight(height)
    self:OnSetHeight(height, oldHeight)
  end
  Defaults.OnSetHeight = nop

  -- Sets the width and height of the object.
  -- Implement OnSetSize(width, height, oldWidth, oldHeight) instead of overriding.
  function Defaults:SetSize(width, height)
    local oldWidth, oldHeight = self:GetWidth(), self:GetHeight()
    if (width < self._defaults_minWidth) then width = self._defaults_minWidth end
    if (height < self._defaults_minHeight) then height = self._defaults_minHeight end
    self:_SetWidth(width)
    self:_SetHeight(height)
    self:OnSetSize(width, height, oldWidth, oldHeight)
  end
  Defaults.OnSetSize = nop

  -- Refreshes the object. Override as required.
  -- Use this function to update the object's appearance.
  Defaults.Refresh = nop

  -- Resizes the object. Override as required.
  -- Use this function to determine and set the object's required size.
  Defaults.Resize = nop
end

-- ============================================================================
-- Initialize object tables
-- ============================================================================

do
  local objects = {
    "Button",
    "CheckButton",
    "ChildFrame",
    "EditBox",
    "FauxScrollFrame",
    "FontString",
    "Frame",
    "ParentFrame",
    "ScrollFrame",
    "Slider",
    "TextArea",
    "Texture"
  }

  for _, k in pairs(objects) do
    assert(DFL[k] == nil)
    DFL[k] = DFL:NewObjectTable()
  end
end
