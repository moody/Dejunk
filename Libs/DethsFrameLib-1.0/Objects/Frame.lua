-- Frame: a frame for DFL objects.

-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

local Alignments = DFL.Alignments
local Directions = DFL.Directions
local Layouts = DFL.Layouts

-- Upvalues
local assert, error, format, ipairs, max, next, pairs, tonumber, type =
      assert, error, format, ipairs, max, next, pairs, tonumber, type
local tinsert, tremove = table.insert, table.remove

-- Frame
local Frame = DFL.Frame

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL frame.
-- @param parent - the parent of the frame
-- @param alignment - the alignment of the frame's children [optional]
-- @param direction - the growth direction of the frame's children [optional]
function Frame:Create(parent, alignment, direction)
  if alignment then assert(Alignments[alignment], format("invalid alignment: \"%s\"", alignment)) end
  if direction then assert(Directions[direction], format("invalid direction: \"%s\"", direction)) end

  local frame = DFL.Creator:CreateFrame(parent)
  frame._alignment = alignment or Alignments.TOPLEFT
  frame._direction = direction or Directions.RIGHT

  frame._alignHelper = DFL.Creator:CreateTexture(frame) -- used to align the canvas with padding in the frame
  frame._canvas = DFL.Creator:CreateTexture(frame) -- used to position children
  frame._canvas:ClearAllPoints()
  frame._canvas:SetPoint(frame._alignment, frame._alignHelper)
  
  frame._padding = {X = 0, Y = 0} -- space between frame edges and children
  frame._spacing = 0 -- space between children

  frame._equalized = false
  frame._flexible = false
  frame._layout = DFL.Layouts.FLOW

  frame._children = {}
  frame._maxChildWidth = 0
  frame._maxChildHeight = 0

  frame._requiredWidth = 0
  frame._requiredHeight = 0

  DFL:AddDefaults(frame)
  DFL:AddMixins(frame, self.Functions)
  
  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

local Functions = Frame.Functions

-- Adds a child object to the frame.
-- @param child - the object to add
-- @param index - the index at which to add the object [optional]
-- @return true if the object was added
function Functions:Add(child, index)
  assert(child, "child cannot be nil")
  if self:Contains(child) then return false end
  if index then
    index = tonumber(index) or error("index must be a number")
    assert((index >= 1) and (index <= #self._children+1), "index out of bounds")
    tinsert(self._children, index, child)
  else
    self._children[#self._children+1] = child
  end
  child:SetParent(self)
  if child.Refresh then child:Refresh() end
  child:Show()
  DFL:ResizeParent(self)
  return true
end

-- Removes a child object from the frame.
-- @param child - the object to remove
-- @return the removed object, or nil if the object was not found
function Functions:Remove(child)
  local index = self:Contains(child)
  if not index then return nil end
  tremove(self._children, index)
  -- child:ClearAllPoints() -- NOTE: Seems to introduce bugs during ParentFrame:SetContent()
  child:Hide()
  DFL:ResizeParent(self)
  return child
end

-- Removes all child objects from the frame.
function Functions:RemoveAll()
  for k, child in pairs(self._children) do
    self._children[k] = nil
    child:ClearAllPoints()
    child:Hide()
  end
  DFL:ResizeParent(self)
end

-- Returns the index of the child if it exists within the frame.
-- @param child - the object to check for
function Functions:Contains(child)
  for i, v in pairs(self._children) do
    if (v == child) then return i end
  end
end

--[[
  Grows children in size based on direction and layout.
  
  Frame children are resized to have equal width or height based on direction.
  Remaining children may be resized to fill space based on layout.
--]]
function Functions:GrowChildren()
  local alignHelper = self._alignHelper
  local children = self._children
  local direction = self._direction
  local fill = (self._layout == Layouts.FILL)
  
  local width, height = alignHelper:GetWidth(), alignHelper:GetHeight()

  -- Horizontal
  if (direction == Directions.RIGHT) or (direction == Directions.LEFT) then
    for _, child in pairs(children) do
      -- If child is a Frame, grow vertically
      if DFL:IsType(child, Frame:GetType()) then
        child:SetHeight(height)
      -- Otherwise, if using FILL layout, distribute any extra width amongst children
      elseif fill then
        local fillWidth = ((width - self:GetRequiredWidth()) / #children) + self._maxChildWidth
        if (fillWidth > 0) then
          for i, child in ipairs(children) do
            child:SetWidth(fillWidth)
          end
        end
        -- Set child heights to alignHelper height
        for i, child in ipairs(children) do child:SetHeight(height) end
      end
    end
  -- Vertical
  elseif (direction == Directions.DOWN) or (direction == Directions.UP) then
    for _, child in pairs(children) do
      -- If child is a Frame, grow horizontally
      if DFL:IsType(child, Frame:GetType()) then
        child:SetWidth(width)
      -- Otherwise, if using FILL layout, distribute any extra height amongst children
      elseif fill then
        local fillHeight = ((height - self:GetRequiredHeight()) / #children) + self._maxChildHeight
        if (fillHeight > 0) then
          for i, child in ipairs(children) do child:SetHeight(fillHeight) end
        end
        -- Set child widths to alignHelper width
        for i, child in ipairs(children) do child:SetWidth(width) end
      end
    end
  else
    error(format("Unsupported direction: \"%s\"", direction))
  end
end

-- Positions all children within the frame.
function Functions:PositionChildren()
  local alignHelper = self._alignHelper
  local alignment = self._alignment
  local canvas = self._canvas
  local children = self._children
  local direction = self._direction
  local flexible = self._flexible
  local fill = (self._layout == Layouts.FILL)
  local spacing = self._spacing

  -- Calculate additional spacing for flexible layouts
  if flexible and (#children > 1) then
    local flexSpacing, diff = 0, 0
    if (direction == Directions.RIGHT) or (direction == Directions.LEFT) then
      diff = alignHelper:GetWidth() - self:GetRequiredWidth()
    elseif (direction == Directions.DOWN) or (direction == Directions.UP) then
      diff = alignHelper:GetHeight() - self:GetRequiredHeight()
    end
    diff = (diff >= 0) and diff or 0
    flexSpacing = diff / (#children - 1)
    spacing = spacing + flexSpacing
  end

  -- Position children
  for i, child in ipairs(children) do
    local prevChild = children[i-1]
    child:ClearAllPoints()

    local p1, p2 -- Points
    local x, y -- Offsets

    -- Determine points
    if flexible and (#children == 1) then
      p1, p2 = Alignments.CENTER, Alignments.CENTER
    elseif (direction == Directions.RIGHT) or (direction == Directions.LEFT) then
      -- Align children by top, center, or bottom
      -- Top
      if (alignment == Alignments.TOPLEFT) or
      (alignment == Alignments.TOP) or
      (alignment == Alignments.TOPRIGHT) then
        p1, p2 = Alignments.TOPLEFT, Alignments.TOPRIGHT
      -- Center
      elseif (alignment == Alignments.LEFT) or
      (alignment == Alignments.CENTER) or
      (alignment == Alignments.RIGHT) then
        p1, p2 = Alignments.LEFT, Alignments.RIGHT
      -- Bottom
      elseif (alignment == Alignments.BOTTOMLEFT) or
      (alignment == Alignments.BOTTOM) or
      (alignment == Alignments.BOTTOMRIGHT) then
        p1, p2 = Alignments.BOTTOMLEFT, Alignments.BOTTOMRIGHT
      end
    elseif (direction == Directions.DOWN) or (direction == Directions.UP) then
      -- Align children by left, center, or right
      -- Left
      if (alignment == Alignments.TOPLEFT) or
      (alignment == Alignments.LEFT) or
      (alignment == Alignments.BOTTOMLEFT) then
        p1, p2 = Alignments.TOPLEFT, Alignments.BOTTOMLEFT
      -- Center
      elseif (alignment == Alignments.TOP) or
      (alignment == Alignments.CENTER) or
      (alignment == Alignments.BOTTOM) then
        p1, p2 = Alignments.TOP, Alignments.BOTTOM
      -- Right
      elseif (alignment == Alignments.TOPRIGHT) or
      (alignment == Alignments.RIGHT) or
      (alignment == Alignments.BOTTOMRIGHT) then
        p1, p2 = Alignments.TOPRIGHT, Alignments.BOTTOMRIGHT
      end
    else
      error(format("Unsupported direction: \"%s\"", direction))
    end

    -- Swap p1 & p2 if reverse
    if (direction == Directions.LEFT) or (direction == Directions.UP) then
      p1, p2 = p2, p1
    end

    -- Determine offsets
    x = ((direction == Directions.RIGHT) and spacing) or
        ((direction == Directions.LEFT) and -spacing) or 0
    y = ((direction == Directions.DOWN) and -spacing) or
        ((direction == Directions.UP) and spacing) or 0

    -- Position child
    if (prevChild) then
      child:SetPoint(p1, prevChild, p2, x, y)
    else
      child:SetPoint(p1, canvas)
    end
  end

  -- Resize canvas to fit children
  local width, height = self._maxChildWidth, self._maxChildHeight
  -- Set width/height for horizontal/vertical directions respectively
  if (direction == Directions.RIGHT) or (direction == Directions.LEFT) then
    width = (flexible or fill) and alignHelper:GetWidth() or self:GetRequiredWidth()
  elseif (direction == Directions.DOWN) or (direction == Directions.UP) then
    height = (flexible or fill) and alignHelper:GetHeight() or self:GetRequiredHeight()
  else
    error(format("Unsupported direction: \"%s\"", direction))
  end

  canvas:SetWidth(width)
  canvas:SetHeight(height)
end

-- ============================================================================
-- Getters & Setters
-- ============================================================================

-- Returns the alignHelper of the frame.
function Functions:GetAlignHelper() return self._alignHelper end
-- Returns the alignment of the frame.
function Functions:GetAlignment() return self._alignment end
-- Returns the canvas of the frame.
function Functions:GetCanvas() return self._canvas end
-- Returns the children of the frame.
function Functions:GetChildren() return self._children end
-- Returns the direction of the frame.
function Functions:GetDirection() return self._direction end
-- Returns the layout of the frame.
function Functions:GetLayout() return self._layout end
-- Returns the frame's padding.
function Functions:GetPadding() return self._padding end
-- Returns the frame's required minimum width.
function Functions:GetRequiredWidth() return self._requiredWidth end
-- Returns the frame's required minimum height.
function Functions:GetRequiredHeight() return self._requiredHeight end
-- Returns the frame's child spacing.
function Functions:GetSpacing() return self._spacing end

-- Sets the alignment of the frame's children.
-- @param _alignment - a value in DFL.Alignments
function Functions:SetAlignment(alignment)
  if alignment then
    assert(Alignments[alignment], format("invalid alignment: \"%s\"", alignment))
  end
  self._alignment = alignment or Alignments.TOPLEFT
  self._canvas:ClearAllPoints()
  self._canvas:SetPoint(self._alignment, self._alignHelper)
  DFL:ResizeParent(self)
end

-- Sets the direction of the frame.
-- @param _direction - a value in DFL.Directions
function Functions:SetDirection(direction)
  if direction then
    assert(Directions[direction], format("invalid direction: \"%s\"", direction))
  end
  self._direction = direction or Directions.RIGHT
  DFL:ResizeParent(self)
end

-- Sets the layout for the frame and resizes the ParentFrame.
-- @param layout - a layout type in DFL.Layouts
function Functions:SetLayout(layout)
  assert(Layouts[layout], format("invalid layout: \"%s\"", tostring(layout)))
  if (layout == self._layout) then return end
  self._layout = layout

  self._equalized = (layout == Layouts.FILL) or
                    (layout == Layouts.FLEX_EQUAL) or
                    (layout == Layouts.FLOW_EQUAL)
  
  self._flexible = (layout == Layouts.FLEX) or
                   (layout == Layouts.FLEX_EQUAL)

  DFL:ResizeParent(self)
end

-- Sets the frame's horizontal and vertical space between its edges and children.
-- @param x - the horizontal space
-- @param y - the vertical space [optional]
function Functions:SetPadding(x, y)
  assert((type(x) == "number") and (x >= 0), "x must be >= 0")
  if y then assert((type(y) == "number") and (y >= 0), "y must be >= 0") end
  self._padding.X = x
  self._padding.Y = y or x
  DFL:ResizeParent(self)
end

-- Sets the frame's horizontal and vertical space between children.
-- @param spacing - the spacing
function Functions:SetSpacing(spacing)
  assert((type(spacing) == "number") and (spacing >= 0), "spacing must be >= 0")
  self._spacing = spacing
  DFL:ResizeParent(self)
end

function Functions:OnSetEnabled(enabled)
  for k, v in pairs(self._children) do
    if v.SetEnabled then v:SetEnabled(enabled) end
  end
end

function Functions:SetColors(color)
  if not self._texture then self._texture = DFL.Texture:Create(self) end
  self._texture:SetColors(color or DFL.Colors.Frame)
end

function Functions:Refresh()
  if self._texture then self._texture:Refresh() end

  for i, child in pairs(self._children) do
    if child.Refresh then child:Refresh() end
  end
end

do -- Resize()
  -- Updates the required width and height of the frame.
  local function updateRequiredSize(self)
    local children = self._children
    local direction = self._direction
    local equalized = self._equalized
    
    local minWidth, minHeight = 0, 0
    local maxChildWidth, maxChildHeight = 0, 0
    local totalSpacing = (#children - 1) * self._spacing
    
    -- Resize children, get largest width and height
    for _, child in pairs(children) do
      if child.Resize then child:Resize() end
      maxChildWidth = max(maxChildWidth, child:GetWidth())
      maxChildHeight = max(maxChildHeight, child:GetHeight())
    end
    self._maxChildWidth = maxChildWidth
    self._maxChildHeight = maxChildHeight

    -- Equalize child sizes if necessary
    if equalized then
      for _, child in pairs(children) do
        if child.SetWidth then child:SetWidth(maxChildWidth) end
        if child.SetHeight then child:SetHeight(maxChildHeight) end
      end
    end
    
    -- Calculate min width & height
    if (direction == Directions.RIGHT) or (direction == Directions.LEFT) then
      -- minHeight, tallest child
      minHeight = maxChildHeight
      -- minWidth, sum of child widths plus total spacing
      if equalized then
        minWidth = (#children * maxChildWidth)
      else
        for _, child in pairs(children) do
          minWidth = minWidth + child:GetWidth()
        end
      end
      minWidth = minWidth + totalSpacing
    elseif (direction == Directions.DOWN) or (direction == Directions.UP) then
      -- minWidth, widest child
      minWidth = maxChildWidth
      -- minHeight, sum of child heights plus total spacing
      if equalized then
        minHeight = (#children * maxChildHeight)
      else
        for _, child in pairs(children) do
          minHeight = minHeight + child:GetHeight()
        end
      end
      minHeight = minHeight + totalSpacing
    end

    self._requiredWidth = minWidth
    self._requiredHeight = minHeight
  end

  function Functions:Resize()
    local alignHelper = self._alignHelper
    local children = self._children
    local direction = self._direction
    local padding = self._padding
    local spacing = self._spacing

    -- Show if children, hide if none
    if next(children) then
      self:Show()
    else
      self:Hide()
      return
    end

    -- Reposition alignHelper
    alignHelper:ClearAllPoints()
    alignHelper:SetPoint("TOPLEFT", self, padding.X, -padding.Y)
    alignHelper:SetPoint("BOTTOMRIGHT", self, -padding.X, padding.Y)

    updateRequiredSize(self)

    -- Set size
    local width = max(self._requiredWidth, self:GetMinWidth()) + (padding.X * 2)
    local height = max(self._requiredHeight, self:GetMinHeight()) + (padding.Y * 2)
    self:SetSize(width, height)
  end
end

do -- OnSetWidth(), OnSetHeight(), OnSetSize()
  local function updateChildren(self)
    self:GrowChildren()
    self:PositionChildren()
  end

  Functions.OnSetWidth = updateChildren
  Functions.OnSetHeight = updateChildren
  Functions.OnSetSize = updateChildren
end
