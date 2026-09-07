-- =============================================================================
-- Waffle: 0.7.1 - https://github.com/moody/Waffle
-- =============================================================================

local _, Addon = ...
Addon.Waffle = {}

--- @class Waffle
local Waffle = Addon.Waffle

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @alias WafflePoint "TOPLEFT" | "TOP" | "TOPRIGHT" | "LEFT" | "CENTER" | "RIGHT" | "BOTTOMLEFT" | "BOTTOM" | "BOTTOMRIGHT"

--- Not necessarily an actual `Frame`. Any table with this shape works:
--- ```
--- frame:ClearAllPoints()
--- frame:Show()
--- frame:Hide()
--- frame:SetWidth(800)
--- frame:SetHeight(600)
--- frame:SetParent(parentFrame)
--- frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 4, -4)
--- ```
--- @class WaffleFrameShape
--- @field ClearAllPoints fun(self: table)
--- @field Hide fun(self: table)
--- @field SetHeight fun(self: table, height: integer)
--- @field SetParent fun(self: table, parent: table)
--- @field SetPoint fun(self: table, point: WafflePoint, relativeTo: table, relativePoint: WafflePoint, offsetX: integer, offsetY: integer)
--- @field SetWidth fun(self: table, width: integer)
--- @field Show fun(self: table)

--- @alias WaffleFrame table | WaffleFrameShape

--- @alias WaffleFlexDirection "ROW" | "COLUMN" | "ROW_REVERSE" | "COLUMN_REVERSE"
--- @alias WaffleFlexAlign "START" | "CENTER" | "END" | "STRETCH"
--- @alias WaffleFlexJustify "START" | "CENTER" | "END" | "SPACE_BETWEEN" | "SPACE_AROUND" | "SPACE_EVENLY"

--- Shared by every node in the tree, root included.
--- @class WaffleFlexNode
--- @field frame? WaffleFrame Cannot be given together with `frameFactory`.
--- @field frameFactory? fun(parent: WaffleFrame): WaffleFrame Cannot be given together with `frame`. `parent` is `nil` for the root, nothing sits above it to pass in.
--- @field defaultFrameFactory? fun(parent: WaffleFrame): WaffleFrame Applies to descendants only, not this node itself.
--- @field children? WaffleFlexNode[] Positioned in a row or column, per `direction`.
--- @field direction? WaffleFlexDirection Default `ROW`. `_REVERSE` keeps the same main axis, only the starting edge (and visual order along it) flips.
--- @field width? integer | "AUTO" | string Always physical/horizontal, regardless of `direction`. `"AUTO"` sums this node's own children's own `width` along its main axis (`direction` is `ROW`), maxes them along its cross axis instead. A percentage string (`"50%"`) resolves against the parent's own `width`, erroring without one available (the root, or a parent whose own `width` is itself still being computed from `"AUTO"`). Has no effect on `minWidth`/`maxWidth`, same as any other fixed `width`.
--- @field height? integer | "AUTO" | string Same as `width`, vertical instead; sums along its main axis when `direction` is `COLUMN`, maxes along its cross axis otherwise, a percentage resolves against the parent's own `height`.
--- @field grow? number This node's own share of its parent's leftover main-axis space, relative to its equally-flexible siblings. Default `1`. No effect on a node with its own explicit main-axis `width`/`height`, or on the root.
--- @field shrink? number This node's own share of its parent's main-axis deficit, when its siblings' own sizes don't all fit. Weighted by this value times this node's own main-axis size, not the value alone. Default `1`; `0` never shrinks below this node's own stated size. No effect on a flexible node (nothing stated to reduce), or on the root.
--- @field align? WaffleFlexAlign Cross-axis alignment for this node's own children. Default `STRETCH`. A child's own `alignSelf` overrides this.
--- @field alignSelf? WaffleFlexAlign Overrides the parent's `align`. No effect on the root.
--- @field justify? WaffleFlexJustify Main-axis distribution of leftover space among this node's own children. Default `START`. No effect if any child has a positive `grow` share, it already claims the leftover space.
--- @field wrap? boolean Overflowing children start a new line instead of continuing past the main axis size. Each line gets its own cross-size (a max over its own children) and stacks after the previous one, `lineGap` between lines too. Default `false`.
--- @field gap? integer Between children only, not the edges. Default `0`.
--- @field lineGap? integer Between wrapped lines only, instead of `gap`. No effect unless `wrap` actually produces more than one. Falls back to `gap` if unset.
--- @field padding? integer On all four sides. Default `0`. Overridden per side by `paddingTop`/`paddingRight`/`paddingBottom`/`paddingLeft`.
--- @field paddingTop? integer Overrides `padding` for the top side only.
--- @field paddingRight? integer Overrides `padding` for the right side only.
--- @field paddingBottom? integer Overrides `padding` for the bottom side only.
--- @field paddingLeft? integer Overrides `padding` for the left side only.
--- @field margin? integer Space around this node itself, on all four sides. Default `0`. Overridden per side by `marginTop`/`marginRight`/`marginBottom`/`marginLeft`.
--- @field marginTop? integer Overrides `margin` for the top side only.
--- @field marginRight? integer Overrides `margin` for the right side only.
--- @field marginBottom? integer Overrides `margin` for the bottom side only.
--- @field marginLeft? integer Overrides `margin` for the left side only.
--- @field minWidth? number A floor on this node's own `width`: the flexible main-axis share, if `width` is main; a `STRETCH`-ed cross-axis size, if cross. No effect on an explicit `width`, or `"AUTO"`. Errors if greater than `maxWidth`.
--- @field maxWidth? number A ceiling on this node's own `width`: the flexible main-axis share, if `width` is main; a `STRETCH`-ed cross-axis size, if cross. No effect on an explicit `width`, or `"AUTO"`. Errors if less than `minWidth`.
--- @field minHeight? number Same as `minWidth`, for `height`.
--- @field maxHeight? number Same as `maxWidth`, for `height`.
--- @field hidden? boolean Excludes this node from layout entirely; siblings reflow to fill the space. Default `false`.
--- @field key? string For lookup via `GetChild(key)`. Duplicate keys aren't validated against, the first match wins.
--- @field order? integer Visual position among siblings, independent of declaration order. Default `0`, ties broken by declaration order. No effect on the root.
--- @field onLayout? fun(component: WaffleFlexComponent, width: integer, height: integer) Fires once the whole `Layout()` pass is resolved and clean, not while it's still running, bottom-up, root last. Mutating a different node from here schedules a future `Layout()` call, the same as any other setter.

-- =============================================================================
-- Internal Data Table
-- =============================================================================

local _W = {}

--- Stand-in for a node's own `children` when it doesn't have any, so
--- reading one that was never set doesn't allocate a fresh empty table on
--- every call. Never assign this to a node's own `children`, only ever
--- read through it.
local EMPTY_CHILDREN = {}

-- =============================================================================
-- Utils
-- =============================================================================

--- Small, otherwise-homeless utilities: each is single-purpose and
--- doesn't share enough with anything else in the file to earn its own
--- category.
_W.Utils = {}

--- Reverses `t` in place.
--- @param t table
function _W.Utils:ReverseArray(t)
  local n = #t
  for i = 1, math.floor(n / 2) do
    t[i], t[n - i + 1] = t[n - i + 1], t[i]
  end
end

--- Resolves `node.frame` in place, creating it via `frameFactory`/
--- `defaultFrameFactory` if neither was already given. `parent` is `nil`
--- for the root, nothing sits above it to hand a factory.
--- @param node WaffleFlexNode
--- @param parent WaffleFrame?
--- @param defaultFrameFactory? fun(parent: WaffleFrame): WaffleFrame
--- @return WaffleFrame
function _W.Utils:ResolveFrame(node, parent, defaultFrameFactory)
  assert(not (node.frame and node.frameFactory),
    "Waffle: node cannot have both `frame` and `frameFactory`")

  if not node.frame then
    local factory = node.frameFactory or defaultFrameFactory
    assert(factory, "Waffle: node has no `frame` and no `frameFactory`/`defaultFrameFactory` was provided")
    node.frame = factory(parent)
    node.frameFactory = nil
  end

  return node.frame
end

--- Parses `node`'s own `direction`, defaulting to `"ROW"`.
--- @param node WaffleFlexNode
--- @return boolean isRow `true` for `"ROW"`/`"ROW_REVERSE"`, `false` for `"COLUMN"`/`"COLUMN_REVERSE"`.
--- @return boolean isReverse `true` for either `_REVERSE` variant.
function _W.Utils:ParseFlexDirection(node)
  local direction = (node.direction or "ROW"):upper()
  return
      (direction == "ROW" or direction == "ROW_REVERSE"),
      (direction == "ROW_REVERSE" or direction == "COLUMN_REVERSE")
end

-- =============================================================================
-- Scratch
-- =============================================================================

--- A small pool of reusable scratch tables for repeated, short-lived use
--- throughout Waffle. Uncapped; a session's own UI tree rarely changes shape,
--- so this settles at a small size on its own and stays there.
_W.Scratch = {
  pool = {}
}

--- Returns an empty table for scratch use: an arbitrary one already in
--- the pool, if it has any, otherwise a fresh table.
--- @return table
function _W.Scratch:Get()
  local t = next(self.pool)
  if not t then return {} end
  self.pool[t] = nil
  return t
end

--- Clears every key in `t` and returns it to the pool for the next
--- caller to reuse. No-ops on `nil`.
--- @param t table?
function _W.Scratch:Release(t)
  if not t then return end
  for k in pairs(t) do t[k] = nil end
  self.pool[t] = true
end

-- =============================================================================
-- DirtyRoots
-- =============================================================================

--- Which root nodes have changed since their last `Layout()` call. Weak
--- keys, an unreferenced root can still be garbage collected.
_W.DirtyRoots = { roots = setmetatable({}, { __mode = "k" }) }

--- Marks the tree containing `node` dirty, wherever its current root is.
--- @param node WaffleFlexNode
function _W.DirtyRoots:Mark(node)
  self.roots[_W.Ownership:FindRoot(node)] = true
end

--- Whether `root` (already resolved by the caller) has changed since its
--- last `Layout()` call.
--- @param root WaffleFlexNode
--- @return boolean
function _W.DirtyRoots:IsDirty(root)
  return self.roots[root] == true
end

--- Clears `root`'s own dirty flag, once its `Layout()` call is done.
--- @param root WaffleFlexNode
function _W.DirtyRoots:Clear(root)
  self.roots[root] = nil
end

-- =============================================================================
-- Ownership
-- =============================================================================

--- Tracks each node's current owner. Weak keys so an unreferenced node
--- can still be garbage collected.
_W.Ownership = {
  byNode = setmetatable({}, { __mode = "k" })
}

--- Claims `node` as a child of `owner`. Errors if it already belongs to
--- a different one, call `DetachComponent()` on that one first to move it.
--- No-ops if `owner` already owns it.
--- @param node WaffleFlexNode
--- @param owner WaffleFlexNode
--- @return boolean claimed `true` if `node` wasn't already `owner`'s, `false` if this was a no-op.
function _W.Ownership:Claim(node, owner)
  local currentOwner = self.byNode[node]
  assert(not currentOwner or currentOwner == owner,
    "Waffle: child already belongs to another component, call DetachComponent() on it first to move it")
  self.byNode[node] = owner
  return currentOwner == nil
end

--- Releases `node`, so it can be claimed by another owner.
--- @param node WaffleFlexNode
function _W.Ownership:Release(node)
  self.byNode[node] = nil
end

--- Detaches `node` from `owner`, if it's actually attached there. `owner`
--- defaults to `node`'s own actual current owner when omitted.
--- @param node WaffleFlexNode
--- @param owner? WaffleFlexNode
--- @return boolean detached
function _W.Ownership:Detach(node, owner)
  owner = owner or self.byNode[node]
  if not owner or self.byNode[node] ~= owner then return false end
  for i, child in ipairs(owner.children or EMPTY_CHILDREN) do
    if child == node then
      table.remove(owner.children, i)
      self:Release(node)
      _W.DeclarationOrder:Unassign(node)
      _W.DirtyRoots:Mark(owner)
      return true
    end
  end
  return false
end

--- Walks up to the tree's actual root, the node with no owner of its
--- own. Found fresh on every call rather than cached, so a moved node's
--- component is never stale.
--- @param node WaffleFlexNode
--- @return WaffleFlexNode
function _W.Ownership:FindRoot(node)
  local owner = self.byNode[node]
  while owner do
    node = owner
    owner = self.byNode[node]
  end
  return node
end

-- =============================================================================
-- DeclarationOrder
-- =============================================================================

--- Used to break `order` ties. Weak keys so an unreferenced child can still
--- be garbage collected.
_W.DeclarationOrder = {
  next = 0,
  byChild = setmetatable({}, { __mode = "k" })
}

--- Returns `child`'s declaration order, `0` if not yet assigned.
--- @param child WaffleFlexNode
--- @return integer
function _W.DeclarationOrder:Get(child)
  return self.byChild[child] or 0
end

--- Assigns `child` the next declaration order. No-ops if it already has one.
--- @param child WaffleFlexNode
function _W.DeclarationOrder:Assign(child)
  if not self.byChild[child] then
    self.next = self.next + 1
    self.byChild[child] = self.next
  end
end

--- Clears `child`'s declaration order, so it's assigned a fresh one if
--- added again later.
--- @param child WaffleFlexNode
function _W.DeclarationOrder:Unassign(child)
  self.byChild[child] = nil
end

-- =============================================================================
-- Sorting
-- =============================================================================

--- Functions for ordering siblings by `order`, ties broken by
--- declaration order.
_W.Sorting = {}

--- Whether `childA` sorts before `childB`, by `order` then declaration order.
--- @param childA WaffleFlexNode
--- @param childB WaffleFlexNode
--- @return boolean
function _W.Sorting:IsFlexChildBefore(childA, childB)
  local orderA, orderB = childA.order or 0, childB.order or 0
  if orderA ~= orderB then
    return orderA < orderB
  end
  local decOrderA, decOrderB = _W.DeclarationOrder:Get(childA), _W.DeclarationOrder:Get(childB)
  return decOrderA < decOrderB
end

--- Sorts `children` in place by `order`, ties broken by declaration
--- order. Custom insertion sort, not `table.sort`: Lua's built-in sort
--- isn't guaranteed stable, which would risk reshuffling those ties.
--- @param children WaffleFlexNode[]
function _W.Sorting:SortFlexChildren(children)
  for i = 2, #children do
    local child = children[i]
    local j = i - 1
    while j >= 1 and self:IsFlexChildBefore(child, children[j]) do
      children[j + 1] = children[j]
      j = j - 1
    end
    children[j + 1] = child
  end
end

-- =============================================================================
-- LayoutCache
-- =============================================================================

--- Internal memoization and table reuse for `Layout()`.
_W.LayoutCache = {}

--- A wrap node's own children, already split into lines by
--- `_W.Sizing:ComputeAutoCrossSize`, for `_W.FlexLayout:Layout` to reuse
--- instead of splitting them again right after. Weak keys so an
--- unreferenced node can still be garbage collected.
_W.LayoutCache.wrapLines = setmetatable({}, { __mode = "k" })

--- Bumped once per `Layout()` pass (see `FlexComponent:Layout()`).
--- Scopes `resolvedDimensions` entries to the pass that computed them,
--- so a stale one from an earlier pass is never reused.
_W.LayoutCache.currentPass = 0

--- `node`'s own `"AUTO"` result per axis, tagged with the pass that
--- computed it. Weak keys so an unreferenced node can still be garbage
--- collected.
_W.LayoutCache.resolvedDimensions = setmetatable({}, { __mode = "k" })

--- Returns `node`'s cached `"AUTO"` result for `axis`, `nil` if it was
--- never computed or is from a stale pass.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @return integer?
function _W.LayoutCache:GetResolvedDimension(node, axis)
  local entry = self.resolvedDimensions[node]
  if entry and entry.pass == self.currentPass then
    return entry[axis]
  end
  return nil
end

--- Records `node`'s `"AUTO"` result for `axis` for the rest of the
--- current pass. Reuses `node`'s own existing entry rather than
--- allocating a new one, resetting it first if it's from a stale pass.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param value integer
function _W.LayoutCache:SetResolvedDimension(node, axis, value)
  local entry = self.resolvedDimensions[node]
  if not entry then
    entry = { pass = self.currentPass }
    self.resolvedDimensions[node] = entry
  elseif entry.pass ~= self.currentPass then
    entry.pass = self.currentPass
    entry.width = nil
    entry.height = nil
  end
  entry[axis] = value
end

--- Returns and clears `node`'s cached wrap lines, even if the caller
--- ends up not using them.
--- @param node WaffleFlexNode
--- @return WaffleFlexNode[][]?
function _W.LayoutCache:GetWrapLines(node)
  local lines = self.wrapLines[node]
  self.wrapLines[node] = nil
  return lines
end

--- Records `node`'s wrap lines for `_W.FlexLayout:Layout` to take right after.
--- @param node WaffleFlexNode
--- @param lines WaffleFlexNode[][]
function _W.LayoutCache:SetWrapLines(node, lines)
  self.wrapLines[node] = lines
end

-- =============================================================================
-- OnLayoutQueue
-- =============================================================================

--- Defers `onLayout` firing until its `Layout()` pass is fully resolved
--- and clean, so a mutation made inside one schedules a future
--- `Layout()` call rather than being lost.
_W.OnLayoutQueue = {}

--- Records `node`'s pending `onLayout` call in `queue`, a table from
--- `_W.Scratch`, fired later by `FireAll`.
--- @param queue table
--- @param node WaffleFlexNode
--- @param width integer
--- @param height integer
function _W.OnLayoutQueue:Add(queue, node, width, height)
  local entry = _W.Scratch:Get()
  entry.node, entry.width, entry.height = node, width, height
  queue[#queue + 1] = entry
end

--- Fires every `onLayout` recorded in `queue`, in the order they were
--- added (bottom-up, children before parents, visual sibling order),
--- releasing each entry back to `_W.Scratch` right after.
--- @param queue table
function _W.OnLayoutQueue:FireAll(queue)
  for i = 1, #queue do
    local entry = queue[i]
    entry.node.onLayout(_W.FlexComponentFactory:New(entry.node), entry.width, entry.height)
    _W.Scratch:Release(entry)
  end
end

-- =============================================================================
-- Sizing
-- =============================================================================

--- Functions for resolving a node's own size along an axis (fixed,
--- percentage, or `"AUTO"`), and clamping a computed size to a node's
--- own `min`/`max`.
_W.Sizing = {}

--- Resolves a shorthand-plus-per-side box value (`padding`, `margin`)
--- for one physical axis: `<prefix>Left`/`<prefix>Right` for `"width"`,
--- `<prefix>Top`/`<prefix>Bottom` for `"height"`. Each side falls back
--- to `node[prefix]` (default `0`) unless given its own value.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param prefix "padding" | "margin"
--- @return number leading
--- @return number trailing
function _W.Sizing:ResolveBoxAxis(node, axis, prefix)
  local shorthand = node[prefix] or 0
  if axis == "width" then
    return node[prefix .. "Left"] or shorthand, node[prefix .. "Right"] or shorthand
  else
    return node[prefix .. "Top"] or shorthand, node[prefix .. "Bottom"] or shorthand
  end
end

--- `child`'s own resolved size along `axis`, plus its own `margin` on
--- both ends. `nil` if it's flexible there.
--- @param child WaffleFlexNode
--- @param axis "width" | "height"
--- @return integer?
function _W.Sizing:ResolveOuterDimension(child, axis)
  local size = self:ResolveDimension(child, axis)
  if not size then
    return nil
  end
  local leading, trailing = self:ResolveBoxAxis(child, axis, "margin")
  return size + leading + trailing
end

--- Computes `node`'s size along its own main axis (`axis`) as the sum of
--- its children's own outer sizes (own size plus `margin`) along that
--- same axis, plus `gap` between them and padding on each end. Errors if
--- any visible child is flexible, there's no space yet for it to split.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @return integer
function _W.Sizing:ComputeAutoSize(node, axis)
  assert(node.children, "Waffle: `\"AUTO\"` needs `children` to compute a size from")

  local gap = node.gap or 0
  local total = 0
  local visibleCount = 0

  for _, child in ipairs(node.children) do
    if not child.hidden then
      visibleCount = visibleCount + 1
      local size = self:ResolveOuterDimension(child, axis)
      if not size then
        error("Waffle: every visible child of an `\"AUTO\"` node needs its own `" ..
          axis .. "`, a flexible child (`nil`) has nothing to split, there's no space yet to split", 0)
      end
      total = total + size
    end
  end

  local leading, trailing = self:ResolveBoxAxis(node, axis, "padding")
  return total + gap * math.max(visibleCount - 1, 0) + leading + trailing
end

--- The max of every one of `children`'s own outer sizes (own size plus
--- `margin`) along `axis`. Errors if any is flexible, there's nothing of
--- its own to measure. The strict counterpart to `LineCrossSize`, which
--- falls back instead.
--- @param children WaffleFlexNode[]
--- @param axis "width" | "height"
--- @return integer
function _W.Sizing:MaxCrossSize(children, axis)
  local max = 0
  for _, child in ipairs(children) do
    local size = self:ResolveOuterDimension(child, axis)
    if not size then
      error("Waffle: every visible child of an `\"AUTO\"` node needs its own `" ..
        axis .. "`, a flexible child (`nil`) has nothing of its own to measure", 0)
    end
    max = math.max(max, size)
  end
  return max
end

--- Computes `node`'s size along its own cross axis (`axis`) as the sum
--- of every line's own `MaxCrossSize`, plus `lineGap` between lines and
--- padding on each end. One line, a flat max with no gap term, unless
--- `node.wrap` is set and its own main axis resolves to a number to wrap
--- against.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param parentWidth? integer Needed only if `node`'s own main axis is itself a percentage.
--- @param parentHeight? integer Same as `parentWidth`, for `height`.
--- @return integer
function _W.Sizing:ComputeAutoCrossSize(node, axis, parentWidth, parentHeight)
  assert(node.children, "Waffle: `\"AUTO\"` needs `children` to compute a cross size from")

  local gap = node.gap or 0
  local lineGap = node.lineGap or gap

  --- @type WaffleFlexNode[]
  local visibleChildren = _W.Scratch:Get()
  for _, child in ipairs(node.children) do
    if not child.hidden then
      table.insert(visibleChildren, child)
    end
  end

  --- @type WaffleFlexNode[][]?
  local lines
  if node.wrap then
    local mainAxis = axis == "width" and "height" or "width"
    local mainSize = self:ResolveDimension(node, mainAxis, parentWidth, parentHeight)
    if mainSize then
      -- Lines have to match what `_W.FlexLayout:Layout` will actually
      -- produce, which sorts before splitting; without this, a child
      -- moved earlier by `order` could land on a different line here
      -- than it really will.
      _W.Sorting:SortFlexChildren(visibleChildren)

      -- `axis` itself (`node`'s own cross axis) is what this whole
      -- function is computing, genuinely unresolvable yet; a child's own
      -- percentage on it errors, same as a child's own `"AUTO"` needing
      -- to sum along it would.
      lines = _W.FlexLayout:SplitFlexLines(visibleChildren, mainAxis, mainSize, nil, gap)

      -- Cached for `node`'s own upcoming `_W.FlexLayout:Layout` call,
      -- which would otherwise redo this same sort and split; released
      -- there instead of here.
      _W.LayoutCache:SetWrapLines(node, lines)
    end
  end

  -- `lines` stays `nil` unless `node.wrap` actually split something:
  -- `visibleChildren` is the one and only line itself then.
  local total, lineCount
  if lines then
    total = 0
    lineCount = #lines
    for _, lineChildren in ipairs(lines) do
      total = total + self:MaxCrossSize(lineChildren, axis)
    end
  else
    total = self:MaxCrossSize(visibleChildren, axis)
    lineCount = 1
  end

  _W.Scratch:Release(visibleChildren)

  local leading, trailing = self:ResolveBoxAxis(node, axis, "padding")
  return total + lineGap * math.max(lineCount - 1, 0) + leading + trailing
end

--- A line's own cross-size: the max of every child's own outer size (own
--- size plus `margin`) along `axis` that has one, skipping any that
--- don't (e.g. a `STRETCH` child on its cross axis) rather than
--- erroring. `fallback` covers a line with nothing explicit at all.
--- @param children WaffleFlexNode[]
--- @param axis "width" | "height"
--- @param fallback integer
--- @return integer
function _W.Sizing:LineCrossSize(children, axis, fallback)
  local max
  for _, child in ipairs(children) do
    local size = self:ResolveOuterDimension(child, axis)
    if size then
      max = max and math.max(max, size) or size
    end
  end
  return max or fallback
end

--- Resolves `node`'s size along `axis`: the given number, a percentage of
--- `parentWidth`/`parentHeight` (whichever matches `axis`), computed from
--- its own children if `"AUTO"` (a sum along `node`'s own main axis, a max
--- along its cross axis), or `nil` if `node` is flexible along `axis`
--- instead. An `"AUTO"` result is cached for the rest of the current
--- pass, a percentage isn't, resolving it is a single multiply.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param parentWidth? integer Needed only if `node`'s own `width` needs it: directly, if `width` is a percentage, or indirectly, if a cross-axis `"AUTO"` needs `width` resolved as a step first.
--- @param parentHeight? integer Same as `parentWidth`, for `height`.
--- @return integer?
function _W.Sizing:ResolveDimension(node, axis, parentWidth, parentHeight)
  local value = node[axis]

  if type(value) ~= "string" then
    return value
  end

  if value == "AUTO" then
    local cached = _W.LayoutCache:GetResolvedDimension(node, axis)
    if cached == nil then
      local isMainAxis = _W.Utils:ParseFlexDirection(node) == (axis == "width")
      cached = (
        isMainAxis and
        self:ComputeAutoSize(node, axis) or
        self:ComputeAutoCrossSize(node, axis, parentWidth, parentHeight)
      )
      _W.LayoutCache:SetResolvedDimension(node, axis, cached)
    end
    return cached
  end

  local number = value:match("^(%d+%.?%d*)%%$")
  number = number and tonumber(number)
  if not number then
    error("Waffle: `" .. axis .. "` must be a number, `\"AUTO\"`, or a percentage string like `\"50%\"`, got `" ..
      value .. "`", 0)
  end

  local parentSize = axis == "width" and parentWidth or parentHeight
  if not parentSize then
    error("Waffle: `" .. axis .. "` given as a percentage needs a resolvable parent `" ..
      axis .. "` to size against; none here, either this is the root or the parent's own `" ..
      axis .. "` is itself still being computed", 0)
  end

  return parentSize * (number / 100)
end

--- Clamps `value` to `node[minField]`/`node[maxField]`, whichever is
--- set. Errors if both are set and the min is greater than the max.
--- @param node WaffleFlexNode
--- @param value number
--- @param minField "minWidth" | "minHeight"
--- @param maxField? "maxWidth" | "maxHeight"
--- @return number
function _W.Sizing:ClampSize(node, value, minField, maxField)
  local min, max = node[minField], node[maxField]
  if min and max and min > max then
    error("Waffle: `" .. minField .. "` cannot be greater than `" .. maxField .. "` on the same node", 0)
  end

  if min and value < min then
    return min
  elseif max and value > max then
    return max
  end

  return value
end

-- =============================================================================
-- SpaceDistributor
-- =============================================================================

--- Functions that resolve how much of a line's own leftover main-axis
--- space or deficit each constrained child gets: freezing whichever
--- hits its min/max bound each round and redistributing the rest, for
--- both `Grow` (growing up from `0`) and `Shrink` (shrinking down from a
--- stated size). Each wraps `Distribute` with its own strategy and
--- extra arguments (none for `Grow`, `statedSizes` for `Shrink`), so a
--- caller never passes `strategy` directly.
_W.SpaceDistributor = {}

--- A size, per child.
--- @alias WaffleFlexNodeSizes table<WaffleFlexNode, number>

--- The shared interface behind `GrowStrategy`/`ShrinkStrategy`,
--- `Distribute`'s only two strategies.
--- @class WaffleSpaceDistributorStrategy
--- @field weight fun(child: WaffleFlexNode, statedSizes?: WaffleFlexNodeSizes): number
--- @field toCandidate fun(child: WaffleFlexNode, share: number, statedSizes?: WaffleFlexNodeSizes): number
--- @field toConsumed fun(child: WaffleFlexNode, clamped: number, statedSizes?: WaffleFlexNodeSizes): number

--- Shared by `Grow` (share itself is the candidate) and `Shrink`
--- (candidate is a node's own stated size minus its share). Plain
--- tables, not closures: both are created once, never per call.
--- @type WaffleSpaceDistributorStrategy
_W.SpaceDistributor.GrowStrategy = {
  weight = function(child) return child.grow or 1 end,
  toCandidate = function(_, share) return share end,
  toConsumed = function(_, clamped) return clamped end,
}

--- @see _W.SpaceDistributor.GrowStrategy
--- @type WaffleSpaceDistributorStrategy
_W.SpaceDistributor.ShrinkStrategy = {
  weight = function(child, statedSizes) return (child.shrink or 1) * statedSizes[child] end,
  toCandidate = function(child, share, statedSizes) return statedSizes[child] - share end,
  toConsumed = function(child, clamped, statedSizes) return statedSizes[child] - clamped end,
}

--- Shared core behind `Grow`/`Shrink`: distributes `mainAxisSpace`
--- proportionally among `constrained` children by `strategy.weight`,
--- clamping each round's own computed value (`strategy.toCandidate`) to
--- `minField`/`maxField`. Freezes (and redistributes the space/weight
--- among the rest) whichever gets clamped, subtracting
--- `strategy.toConsumed` from `mainAxisSpace` each time, until a round
--- freezes nobody new. The two only differ in what a raw share becomes,
--- not in how the space/weight get redistributed round to round.
--- @param constrained WaffleFlexNode[] Only children with `minField` and/or `maxField` set; the caller filters out everyone else, nothing else could ever violate a bound.
--- @param mainAxisSpace number Space to give out (`Grow`) or claim back (`Shrink`).
--- @param totalWeight number Sum of every `constrained` child's own `strategy.weight`.
--- @param minField "minWidth" | "minHeight"
--- @param maxField? "maxWidth" | "maxHeight"
--- @param strategy WaffleSpaceDistributorStrategy
--- @vararg any Passed through to every one of `strategy`'s own functions, as their final argument(s).
--- @return WaffleFlexNodeSizes? frozen `nil` unless a round actually froze someone; pooled, the caller releases it once done.
--- @return number mainAxisSpace Floored at `0`, a min floor can claim more than `mainAxisSpace` has left to give.
--- @return number totalWeight Reduced by every frozen child's own weight, leaving just the unfrozen ones' total.
function _W.SpaceDistributor:Distribute(constrained, mainAxisSpace, totalWeight, minField, maxField, strategy, ...)
  local frozen
  local frozeAny = true
  while frozeAny and totalWeight > 0 do
    frozeAny = false
    local roundMainAxisSpace, roundWeight = mainAxisSpace, totalWeight
    for _, child in ipairs(constrained) do
      if not (frozen and frozen[child]) then
        local childWeight = strategy.weight(child, ...)
        local share = roundWeight > 0 and (roundMainAxisSpace * childWeight / roundWeight) or 0
        local candidate = strategy.toCandidate(child, share, ...)
        local clamped = _W.Sizing:ClampSize(child, candidate, minField, maxField)

        if clamped ~= candidate then
          frozen = frozen or _W.Scratch:Get()
          frozen[child] = clamped
          mainAxisSpace = mainAxisSpace - strategy.toConsumed(child, clamped, ...)
          totalWeight = totalWeight - childWeight
          frozeAny = true
        end
      end
    end
  end
  return frozen, math.max(mainAxisSpace, 0), totalWeight
end

--- Distributes leftover main-axis space among flexible children, each
--- growing up from `0`, clamped to `minField`/`maxField`.
--- @param constrained WaffleFlexNode[] Only children with `minField` and/or `maxField` set; the caller filters out everyone else, nothing else could ever violate a bound.
--- @param mainAxisSpace number Leftover main-axis space to give out.
--- @param totalWeight number Sum of every `constrained` child's own `grow` (default `1`).
--- @param minField "minWidth" | "minHeight"
--- @param maxField? "maxWidth" | "maxHeight"
--- @return WaffleFlexNodeSizes? frozen `nil` unless a round actually froze someone; pooled, the caller releases it once done.
--- @return number mainAxisSpace Floored at `0`, a min floor can claim more than `mainAxisSpace` has left to give.
--- @return number totalWeight Reduced by every frozen child's own weight, leaving just the unfrozen ones' total.
function _W.SpaceDistributor:Grow(constrained, mainAxisSpace, totalWeight, minField, maxField)
  return self:Distribute(constrained, mainAxisSpace, totalWeight, minField, maxField, self.GrowStrategy)
end

--- Distributes a main-axis deficit among fixed/percentage children, each
--- shrinking down from its own stated size in `statedSizes`, clamped to
--- `minField`. `maxField` never applies, a child only ever shrinks down
--- from it, never up past it.
--- @param constrained WaffleFlexNode[] Only children with `minField` set; the caller filters out everyone else, nothing else could ever violate the floor.
--- @param mainAxisSpace number Main-axis deficit to claim back.
--- @param totalWeight number Sum of every `constrained` child's own `shrink` (default `1`) times its own stated size.
--- @param minField "minWidth" | "minHeight"
--- @param statedSizes WaffleFlexNodeSizes Each `constrained` child's own already-resolved size; `shrink`'s own weight formula needs it every round, not just once.
--- @return WaffleFlexNodeSizes? frozen `nil` unless a round actually froze someone; pooled, the caller releases it once done.
--- @return number mainAxisSpace Floored at `0`, a min floor can claim more than `mainAxisSpace` has left to give.
--- @return number totalWeight Reduced by every frozen child's own weight, leaving just the unfrozen ones' total.
function _W.SpaceDistributor:Shrink(constrained, mainAxisSpace, totalWeight, minField, statedSizes)
  return self:Distribute(constrained, mainAxisSpace, totalWeight, minField, nil, self.ShrinkStrategy, statedSizes)
end

-- =============================================================================
-- FlexLayout
-- =============================================================================

--- Functions that position `node.children` in a row or column,
--- splitting into wrapped lines first when needed.
_W.FlexLayout = {}

--- Splits `children` (already sorted, already visible-only) into lines
--- along `axis`: each line is as many children as fit within `mainSize`,
--- in order, counting each child's own `margin` as part of its size. A
--- fixed-size child that would overflow the current line starts a new
--- one instead, unless the current line is still empty, a lone child
--- bigger than `mainSize` still gets placed on one rather than looping
--- forever. A flexible child (no fixed size of its own yet) always joins
--- the current line, there's nothing of its own yet to check for
--- overflow, though its `margin` still counts toward the running total.
--- @param children WaffleFlexNode[]
--- @param axis "width" | "height"
--- @param mainSize integer
--- @param crossSize? integer The container's own cross size, if resolved yet; needed only for a child's own percentage/`"AUTO"` along that axis. `nil` from `_W.Sizing:ComputeAutoCrossSize`, that's the container's own cross axis, what it's still computing.
--- @param gap integer
--- @return WaffleFlexNode[][] lines Pooled, `lines` itself and every line in it; released by whichever of `_W.Sizing:ComputeAutoCrossSize`/`Layout` is done reading them.
function _W.FlexLayout:SplitFlexLines(children, axis, mainSize, crossSize, gap)
  --- @type WaffleFlexNode[][]
  local lines = _W.Scratch:Get()
  --- @type WaffleFlexNode[]
  local currentLine = _W.Scratch:Get()
  local currentLineTotal = 0

  local parentWidth = axis == "width" and mainSize or crossSize
  local parentHeight = axis == "height" and mainSize or crossSize

  for _, child in ipairs(children) do
    local size = _W.Sizing:ResolveDimension(child, axis, parentWidth, parentHeight)
    local marginLeading, marginTrailing = _W.Sizing:ResolveBoxAxis(child, axis, "margin")
    local margin = marginLeading + marginTrailing
    local outerSize = size and (size + margin)

    if outerSize and #currentLine > 0 and currentLineTotal + gap + outerSize > mainSize then
      table.insert(lines, currentLine)
      currentLine = _W.Scratch:Get()
      currentLineTotal = 0
    end

    table.insert(currentLine, child)
    currentLineTotal = currentLineTotal + (outerSize or margin) + (#currentLine > 1 and gap or 0)
  end

  if #currentLine > 0 then
    table.insert(lines, currentLine)
  end

  return lines
end

--- Resolves how much of `lineChildren`'s own leftover main-axis space
--- (positive, `grow` splits it) or deficit (negative, `shrink` gives
--- some back) goes to each flexible/fixed child, via
--- `_W.SpaceDistributor:Grow` for flexible children (growing up from
--- `0`, clamped to `min`/`max`) and `_W.SpaceDistributor:Shrink` for
--- fixed/percentage ones (shrinking down from each one's own stated
--- size, clamped to `min`, weighted by `shrink` times that size, not
--- `shrink` alone). Both are skipped for a child with neither bound
--- set, `LayoutFlexLine` computes its own fallback share directly
--- instead.
--- @param lineChildren WaffleFlexNode[]
--- @param mainAxis "width" | "height"
--- @param mainSize integer
--- @param crossSize integer Needed only for a child's own percentage/`"AUTO"` along the cross axis.
--- @param gap integer
--- @return WaffleFlexNodeSizes? clampedSizes `nil` unless a flexible child on this line actually ends up clamped; pooled, `LayoutFlexLine` releases it once done, not this function.
--- @return number remaining Unclaimed space after every child's own share and `margin`, for `justify`. `0` whenever there's a deficit instead.
--- @return number totalGrow Surviving flexible weight, `0` once nothing has a positive share left.
--- @return WaffleFlexNodeSizes? shrunkSizes `nil` unless a fixed/percentage child on this line actually ends up shrunk; pooled, `LayoutFlexLine` releases it once done, not this function.
--- @return number deficit How much `lineChildren`'s own sizes overflow `mainSize` by, `0` unless they actually do.
--- @return number totalShrink Surviving shrinkable weight, `0` once nothing has a positive share left to give.
function _W.FlexLayout:ResolveLineSizes(lineChildren, mainAxis, mainSize, crossSize, gap)
  local isRow = mainAxis == "width"
  local minField = isRow and "minWidth" or "minHeight"
  local maxField = isRow and "maxWidth" or "maxHeight"
  local visibleCount = #lineChildren

  local parentWidth = isRow and mainSize or crossSize
  local parentHeight = isRow and crossSize or mainSize

  local fixedTotal = 0
  local totalGrow = 0
  local totalShrink = 0

  --- @type WaffleFlexNode[]
  local growConstrained
  --- @type WaffleFlexNode[]
  local shrinkConstrained
  -- Each `shrinkConstrained` child's own stated size, `shrink`'s own
  -- weight formula needs it on every round, not just once.
  --- @type WaffleFlexNodeSizes
  local statedSizes
  for _, child in ipairs(lineChildren) do
    local marginLeading, marginTrailing = _W.Sizing:ResolveBoxAxis(child, mainAxis, "margin")
    fixedTotal = fixedTotal + marginLeading + marginTrailing

    local size = _W.Sizing:ResolveDimension(child, mainAxis, parentWidth, parentHeight)
    if size then
      fixedTotal = fixedTotal + size
      totalShrink = totalShrink + (child.shrink or 1) * size
      if child[minField] then
        shrinkConstrained = shrinkConstrained or _W.Scratch:Get()
        shrinkConstrained[#shrinkConstrained + 1] = child
        statedSizes = statedSizes or _W.Scratch:Get()
        statedSizes[child] = size
      end
    else
      totalGrow = totalGrow + (child.grow or 1)
      if child[minField] or child[maxField] then
        growConstrained = growConstrained or _W.Scratch:Get()
        growConstrained[#growConstrained + 1] = child
      end
    end
  end

  local totalGap = gap * math.max(visibleCount - 1, 0)
  local rawRemaining = mainSize - fixedTotal - totalGap
  local remaining = math.max(rawRemaining, 0)
  local deficit = math.max(-rawRemaining, 0)

  --- @type WaffleFlexNodeSizes
  local clampedSizes
  if growConstrained then
    clampedSizes, remaining, totalGrow = _W.SpaceDistributor:Grow(growConstrained, remaining, totalGrow, minField,
      maxField)
  end

  --- @type WaffleFlexNodeSizes
  local shrunkSizes
  if deficit > 0 and shrinkConstrained then
    shrunkSizes, deficit, totalShrink = _W.SpaceDistributor:Shrink(shrinkConstrained, deficit, totalShrink, minField,
      statedSizes)
  end

  _W.Scratch:Release(growConstrained)
  _W.Scratch:Release(shrinkConstrained)
  _W.Scratch:Release(statedSizes)

  return clampedSizes, remaining, totalGrow, shrunkSizes, deficit, totalShrink
end

--- Resolves `node.justify`'s main-axis offset/gap for one line. A child
--- with a positive `grow` share already claims some or all of
--- `remaining`, `justify` only has anything left once no child does,
--- `totalGrow == 0`.
--- @param node WaffleFlexNode
--- @param totalGrow number
--- @param remaining number
--- @param visibleCount integer
--- @param isReverse boolean If true, swaps `START`/`END`, since the packing math itself has no other way to know the main-start edge moved. `CENTER`/`SPACE_*` need no such swap, already symmetric.
--- @return number justifyOffset
--- @return number justifyGap
function _W.FlexLayout:ResolveLineJustify(node, totalGrow, remaining, visibleCount, isReverse)
  if totalGrow ~= 0 then
    return 0, 0
  end

  local justifyOffset, justifyGap = 0, 0
  local justify = (node.justify or "START"):upper()
  if isReverse then
    if justify == "START" then
      justify = "END"
    elseif justify == "END" then
      justify = "START"
    end
  end

  if justify == "END" then
    justifyOffset = remaining
  elseif justify == "CENTER" then
    justifyOffset = remaining / 2
  elseif justify == "SPACE_BETWEEN" and visibleCount > 1 then
    justifyGap = remaining / (visibleCount - 1)
  elseif justify == "SPACE_AROUND" and visibleCount > 0 then
    justifyGap = remaining / visibleCount
    justifyOffset = justifyGap / 2
  elseif justify == "SPACE_EVENLY" then
    justifyGap = remaining / (visibleCount + 1)
    justifyOffset = justifyGap
  end

  return justifyOffset, justifyGap
end

--- Positions `lineChildren` along `mainAxis`, starting at `mainStart`, and
--- aligns each within `crossSize` starting at `crossStart`. One line is
--- every one of `node.children` when `node.wrap` isn't set, or one
--- wrapped line's worth of them when it is. Non-`STRETCH` alignment
--- requires the child's own cross-axis value, it never falls back to
--- stretching; `STRETCH` itself clamps to the child's own cross-axis
--- `min`/`max`, if either is set. Each child's own `margin` insets it
--- from wherever it would otherwise sit, on both axes.
--- @param node WaffleFlexNode
--- @param frame WaffleFrame
--- @param lineChildren WaffleFlexNode[]
--- @param mainAxis "width" | "height"
--- @param crossAxis "width" | "height"
--- @param isReverse boolean If true, `lineChildren` arrives already reversed by the caller.
--- @param mainSize integer
--- @param crossSize integer
--- @param mainStart integer
--- @param crossStart integer
--- @param defaultFrameFactory? fun(parent: WaffleFrame): WaffleFrame
--- @param onLayoutQueue table Passed through to a `children` recursion; a visited child's own `onLayout` (if any) is queued onto it, not fired yet.
function _W.FlexLayout:LayoutFlexLine(node, frame, lineChildren, mainAxis, crossAxis, isReverse, mainSize, crossSize,
                                      mainStart, crossStart, defaultFrameFactory, onLayoutQueue)
  local gap = node.gap or 0
  local isRow = mainAxis == "width"
  local visibleCount = #lineChildren
  local crossMinField = isRow and "minHeight" or "minWidth"
  local crossMaxField = isRow and "maxHeight" or "maxWidth"

  local parentWidth = isRow and mainSize or crossSize
  local parentHeight = isRow and crossSize or mainSize

  local clampedSizes, remaining, totalGrow, shrunkSizes, deficit, totalShrink =
      self:ResolveLineSizes(lineChildren, mainAxis, mainSize, crossSize, gap)
  local justifyOffset, justifyGap = self:ResolveLineJustify(node, totalGrow, remaining, visibleCount, isReverse)

  local mainOffset = mainStart + justifyOffset
  for _, child in ipairs(lineChildren) do
    local childFrame = _W.Utils:ResolveFrame(child, frame, defaultFrameFactory)

    childFrame:Show()
    childFrame:ClearAllPoints()
    childFrame:SetParent(frame)

    local size = _W.Sizing:ResolveDimension(child, mainAxis, parentWidth, parentHeight)
    if size then
      if shrunkSizes and shrunkSizes[child] then
        size = shrunkSizes[child]
      elseif deficit > 0 and totalShrink > 0 then
        size = size - deficit * (child.shrink or 1) * size / totalShrink
      end
    else
      size = clampedSizes and clampedSizes[child]
      if not size then
        size = totalGrow > 0 and (remaining * (child.grow or 1) / totalGrow) or 0
      end
    end

    local marginMainLeading, marginMainTrailing = _W.Sizing:ResolveBoxAxis(child, mainAxis, "margin")
    local marginCrossLeading, marginCrossTrailing = _W.Sizing:ResolveBoxAxis(child, crossAxis, "margin")

    local align = (child.alignSelf or node.align or "STRETCH"):upper()
    local childCrossSize
    if align == "STRETCH" then
      childCrossSize = _W.Sizing:ResolveDimension(child, crossAxis, parentWidth, parentHeight) or
          _W.Sizing:ClampSize(child, crossSize - marginCrossLeading - marginCrossTrailing, crossMinField, crossMaxField)
    else
      childCrossSize = _W.Sizing:ResolveDimension(child, crossAxis, parentWidth, parentHeight)
      if not childCrossSize then
        error("Waffle: a child aligned '" ..
          align ..
          "' (not 'STRETCH') needs its own `" ..
          crossAxis .. "`, alignment doesn't fall back to the container's cross size", 0)
      end
    end

    local crossOffset = crossStart + marginCrossLeading
    if align == "CENTER" or align == "END" then
      local outerCrossSize = childCrossSize + marginCrossLeading + marginCrossTrailing
      local leftover = crossSize - outerCrossSize
      crossOffset = crossStart + (align == "CENTER" and leftover / 2 or leftover) + marginCrossLeading
    end

    local childMainOffset = mainOffset + marginMainLeading
    local childWidth, childHeight

    if isRow then
      childWidth, childHeight = size, childCrossSize
      childFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", childMainOffset, -crossOffset)
    else
      childWidth, childHeight = childCrossSize, size
      childFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", crossOffset, -childMainOffset)
    end

    childFrame:SetWidth(childWidth)
    childFrame:SetHeight(childHeight)

    if child.children then
      self:Layout(child, childFrame, childWidth, childHeight, child.defaultFrameFactory or defaultFrameFactory,
        onLayoutQueue)
    end

    if child.onLayout then
      _W.OnLayoutQueue:Add(onLayoutQueue, child, childWidth, childHeight)
    end

    mainOffset = mainOffset + marginMainLeading + size + marginMainTrailing + gap + justifyGap
  end

  -- Acquired by `ResolveLineSizes`, released here instead: still read by
  -- the loop above.
  _W.Scratch:Release(clampedSizes)
  _W.Scratch:Release(shrunkSizes)
end

--- Positions `node.children` in a row or column within `frame`, sized to
--- `width`/`height`, one line (`node.wrap` unset) or several (`node.wrap`
--- set, overflowing children start a new one instead of continuing past
--- `mainSize`). `frame` must already be resolved/sized by the caller.
--- @param node WaffleFlexNode
--- @param frame WaffleFrame
--- @param width integer
--- @param height integer
--- @param defaultFrameFactory? fun(parent: WaffleFrame): WaffleFrame
--- @param onLayoutQueue table Passed through to `LayoutFlexLine`/nested `children` recursions; every visited node's own `onLayout` (if any) is queued onto it, not fired yet.
function _W.FlexLayout:Layout(node, frame, width, height, defaultFrameFactory, onLayoutQueue)
  local isRow, isReverse = _W.Utils:ParseFlexDirection(node)
  local mainAxis = isRow and "width" or "height"
  local crossAxis = isRow and "height" or "width"

  local mainLeading, mainTrailing = _W.Sizing:ResolveBoxAxis(node, mainAxis, "padding")
  local crossLeading, crossTrailing = _W.Sizing:ResolveBoxAxis(node, crossAxis, "padding")

  local mainSize = (isRow and width or height) - mainLeading - mainTrailing
  local crossSize = (isRow and height or width) - crossLeading - crossTrailing

  -- Declaration order/ownership are assigned here, not in their own pass,
  -- since this loop is already walking every child anyway. `children` is
  -- a scratch copy of `node.children`, not `node.children` itself, so
  -- sorting it doesn't disturb `GetChildren()`'s own declaration-order
  -- guarantee. Pooled; released right below, once this function is done
  -- reading it.
  --- @type WaffleFlexNode[]
  local children = _W.Scratch:Get()
  for i, child in ipairs(node.children) do
    _W.DeclarationOrder:Assign(child)
    _W.Ownership:Claim(child, node)
    children[i] = child
  end

  _W.Sorting:SortFlexChildren(children)

  -- Reuses lines a cross-axis `"AUTO"` computation already split `node`
  -- into, instead of splitting them again.
  local wrapLines = _W.LayoutCache:GetWrapLines(node)
  local lines = node.wrap and wrapLines or nil

  -- Hidden children are hidden and dropped here, once, so neither
  -- `SplitFlexLines` nor `LayoutFlexLine` needs to care about them at
  -- all. Left `nil`, not built, when `lines` already covers `node`.
  -- Pooled; released below, safe by then either way: `SplitFlexLines`
  -- is done with it under `wrap`, and `LayoutFlexLine` already returned
  -- without it.
  --- @type WaffleFlexNode[]?
  local visibleChildren = not lines and _W.Scratch:Get() or nil

  local visibleCount = 0
  for _, child in ipairs(children) do
    if child.hidden then
      if child.frame then
        child.frame:Hide()
      end
    elseif visibleChildren then
      visibleCount = visibleCount + 1
      visibleChildren[visibleCount] = child
    end
  end

  _W.Scratch:Release(children)

  if node.wrap then
    local gap = node.gap or 0
    local lineGap = node.lineGap or gap
    local crossOffset = crossLeading

    -- Pooled either way, from `SplitFlexLines`, whether `lines` came
    -- from `_W.Sizing:ComputeAutoCrossSize`'s own cached call or gets
    -- split fresh here. Released below: `lineChildren` once its own
    -- line is done, `lines` once every line is.
    --- @type WaffleFlexNode[][]
    lines = lines or self:SplitFlexLines(visibleChildren, mainAxis, mainSize, crossSize, gap)
    for _, lineChildren in ipairs(lines) do
      if isReverse then
        _W.Utils:ReverseArray(lineChildren)
      end

      local thisLineCrossSize = _W.Sizing:LineCrossSize(lineChildren, crossAxis, crossSize)
      self:LayoutFlexLine(node, frame, lineChildren, mainAxis, crossAxis, isReverse, mainSize, thisLineCrossSize,
        mainLeading, crossOffset, defaultFrameFactory, onLayoutQueue)
      crossOffset = crossOffset + thisLineCrossSize + lineGap

      _W.Scratch:Release(lineChildren)
    end
    _W.Scratch:Release(lines)
  else
    if isReverse then
      _W.Utils:ReverseArray(visibleChildren)
    end

    self:LayoutFlexLine(node, frame, visibleChildren, mainAxis, crossAxis, isReverse, mainSize, crossSize, mainLeading,
      crossLeading, defaultFrameFactory, onLayoutQueue)
  end

  _W.Scratch:Release(visibleChildren)
end

-- =============================================================================
-- FlexComponent
-- =============================================================================

--- Wraps a single node, regardless of whether it has children: that's a
--- fact about the node, not a distinct type, so one component covers
--- both. Returned by `Waffle:Flex()`, `AddChild`, `AddRow`, `AddColumn`,
--- `AttachComponent`, `GetChild`, and `GetChildren`.
--- @class WaffleFlexComponent
--- @field package node WaffleFlexNode
_W.FlexComponent = {}
_W.FlexComponent.__index = _W.FlexComponent

--- Never `setmetatable`'d onto anything: a `FlexComponent` method is
--- reachable from any component a consumer holds (it is that component's
--- own metatable), so construction stays a separate table instead, out
--- of reach from `someComponent:___()`.
_W.FlexComponentFactory = {}

--- Constructs a component wrapping `node` as-is.
--- @param node WaffleFlexNode
--- @return WaffleFlexComponent
function _W.FlexComponentFactory:New(node)
  return setmetatable({ node = node }, _W.FlexComponent)
end

--- Recursively searches `node` and its descendants, depth-first, for one
--- whose `key` matches, returning the first found. Records itself as the
--- current owner of every node it visits along the way.
--- @param node WaffleFlexNode
--- @param key string
--- @return WaffleFlexNode?
function _W.FlexComponentFactory:FindNodeByKey(node, key)
  if node.key == key then
    return node
  end
  if node.children then
    for _, child in ipairs(node.children) do
      _W.Ownership:Claim(child, node)
      local found = self:FindNodeByKey(child, key)
      if found then
        return found
      end
    end
  end
end

-- Every setter below is a no-op unless the value actually changes, so
-- redundant calls (e.g. from a per-frame OnUpdate) stay cheap. Ordered to
-- match `WaffleFlexNode`'s own field declaration order above.

--- Sets a frame factory for any descendant that gives neither `frame` nor
--- its own `frameFactory`. `nil` removes it. An already-resolved
--- descendant's own `frame` is unaffected either way, only one still
--- waiting on a factory picks up the change.
--- @param defaultFrameFactory? fun(parent: WaffleFrame): WaffleFrame
function _W.FlexComponent:SetDefaultFrameFactory(defaultFrameFactory)
  if self.node.defaultFrameFactory ~= defaultFrameFactory then
    self.node.defaultFrameFactory = defaultFrameFactory
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets this node's own main axis for its own children. `nil` resets to
--- the default (`"ROW"`).
--- @param direction? WaffleFlexDirection
function _W.FlexComponent:SetDirection(direction)
  if self.node.direction ~= direction then
    self.node.direction = direction
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets this node's own width. `nil` flexes/stretches instead; `"AUTO"`
--- computes it from this node's own children (a sum along its main axis,
--- a max along its cross axis); a percentage string (`"50%"`) resolves
--- against the parent's own width.
--- @param width? integer | "AUTO" | string
function _W.FlexComponent:SetWidth(width)
  if self.node.width ~= width then
    self.node.width = width
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets this node's own height. Same as `SetWidth()`, vertical instead.
--- @param height? integer | "AUTO" | string
function _W.FlexComponent:SetHeight(height)
  if self.node.height ~= height then
    self.node.height = height
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets this node's own width and height together, equivalent to `SetWidth()`/`SetHeight()`.
--- Omitting either argument passes nil, resetting that dimension instead of leaving it unchanged.
--- @param width? integer | "AUTO" | string
--- @param height? integer | "AUTO" | string
function _W.FlexComponent:SetSize(width, height)
  self:SetWidth(width)
  self:SetHeight(height)
end

--- Sets this node's own share of its parent's leftover main-axis space,
--- relative to its equally-flexible siblings. `nil` resets to the
--- default (`1`).
--- @param grow? number
function _W.FlexComponent:SetGrow(grow)
  if self.node.grow ~= grow then
    self.node.grow = grow
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets this node's own share of its parent's main-axis deficit. `nil`
--- resets to the default (`1`).
--- @param shrink? number
function _W.FlexComponent:SetShrink(shrink)
  if self.node.shrink ~= shrink then
    self.node.shrink = shrink
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets how this node aligns its own children along the cross axis by default.
--- @param align? WaffleFlexAlign
function _W.FlexComponent:SetAlign(align)
  if self.node.align ~= align then
    self.node.align = align
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides the parent's `align` for this node. `nil` reverts to inheriting it.
--- @param alignSelf? WaffleFlexAlign
function _W.FlexComponent:SetAlignSelf(alignSelf)
  if self.node.alignSelf ~= alignSelf then
    self.node.alignSelf = alignSelf
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets how this node distributes leftover main-axis space among its own children.
--- @param justify? WaffleFlexJustify
function _W.FlexComponent:SetJustify(justify)
  if self.node.justify ~= justify then
    self.node.justify = justify
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets whether this node's overflowing children wrap onto a new line.
--- @param wrap? boolean
function _W.FlexComponent:SetWrap(wrap)
  if self.node.wrap ~= wrap then
    self.node.wrap = wrap
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets the space between this node's own children.
--- @param gap? integer
function _W.FlexComponent:SetGap(gap)
  if self.node.gap ~= gap then
    self.node.gap = gap
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets the space between this node's own wrapped lines, instead of
--- `SetGap()`. `nil` falls back to it.
--- @param lineGap? integer
function _W.FlexComponent:SetLineGap(lineGap)
  if self.node.lineGap ~= lineGap then
    self.node.lineGap = lineGap
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets the space between this node's edge and its own children, on all
--- four sides. Overridden per side by `SetPaddingTop()`/`SetPaddingRight()`/
--- `SetPaddingBottom()`/`SetPaddingLeft()`.
--- @param padding? integer
function _W.FlexComponent:SetPadding(padding)
  if self.node.padding ~= padding then
    self.node.padding = padding
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides `SetPadding()` for this node's top side only. `nil` reverts
--- to it.
--- @param paddingTop? integer
function _W.FlexComponent:SetPaddingTop(paddingTop)
  if self.node.paddingTop ~= paddingTop then
    self.node.paddingTop = paddingTop
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides `SetPadding()` for this node's right side only. `nil`
--- reverts to it.
--- @param paddingRight? integer
function _W.FlexComponent:SetPaddingRight(paddingRight)
  if self.node.paddingRight ~= paddingRight then
    self.node.paddingRight = paddingRight
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides `SetPadding()` for this node's bottom side only. `nil`
--- reverts to it.
--- @param paddingBottom? integer
function _W.FlexComponent:SetPaddingBottom(paddingBottom)
  if self.node.paddingBottom ~= paddingBottom then
    self.node.paddingBottom = paddingBottom
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides `SetPadding()` for this node's left side only. `nil` reverts
--- to it.
--- @param paddingLeft? integer
function _W.FlexComponent:SetPaddingLeft(paddingLeft)
  if self.node.paddingLeft ~= paddingLeft then
    self.node.paddingLeft = paddingLeft
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets the space around this node itself, on all four sides. `nil`
--- removes it. Overridden per side by `SetMarginTop()`/`SetMarginRight()`/
--- `SetMarginBottom()`/`SetMarginLeft()`.
--- @param margin? integer
function _W.FlexComponent:SetMargin(margin)
  if self.node.margin ~= margin then
    self.node.margin = margin
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides `SetMargin()` for this node's top side only. `nil` reverts
--- to it.
--- @param marginTop? integer
function _W.FlexComponent:SetMarginTop(marginTop)
  if self.node.marginTop ~= marginTop then
    self.node.marginTop = marginTop
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides `SetMargin()` for this node's right side only. `nil`
--- reverts to it.
--- @param marginRight? integer
function _W.FlexComponent:SetMarginRight(marginRight)
  if self.node.marginRight ~= marginRight then
    self.node.marginRight = marginRight
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides `SetMargin()` for this node's bottom side only. `nil`
--- reverts to it.
--- @param marginBottom? integer
function _W.FlexComponent:SetMarginBottom(marginBottom)
  if self.node.marginBottom ~= marginBottom then
    self.node.marginBottom = marginBottom
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Overrides `SetMargin()` for this node's left side only. `nil` reverts
--- to it.
--- @param marginLeft? integer
function _W.FlexComponent:SetMarginLeft(marginLeft)
  if self.node.marginLeft ~= marginLeft then
    self.node.marginLeft = marginLeft
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets a floor on this node's own `width`. `nil` removes it.
--- @param minWidth? number
function _W.FlexComponent:SetMinWidth(minWidth)
  if self.node.minWidth ~= minWidth then
    self.node.minWidth = minWidth
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets a ceiling on this node's own `width`. `nil` removes it.
--- @param maxWidth? number
function _W.FlexComponent:SetMaxWidth(maxWidth)
  if self.node.maxWidth ~= maxWidth then
    self.node.maxWidth = maxWidth
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets a floor on this node's own `height`. `nil` removes it.
--- @param minHeight? number
function _W.FlexComponent:SetMinHeight(minHeight)
  if self.node.minHeight ~= minHeight then
    self.node.minHeight = minHeight
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets a ceiling on this node's own `height`. `nil` removes it.
--- @param maxHeight? number
function _W.FlexComponent:SetMaxHeight(maxHeight)
  if self.node.maxHeight ~= maxHeight then
    self.node.maxHeight = maxHeight
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets this node's own `key`, for lookup via `GetChild(key)`. `nil`
--- removes it. Unlike every other setter, never marks the tree dirty:
--- `GetChild` always searches live, there's nothing to recompute.
--- @param key? string
function _W.FlexComponent:SetKey(key)
  self.node.key = key
end

--- Sets this node's visual position among siblings, independent of
--- declaration order. `nil` resets to the default.
--- @param order? integer
function _W.FlexComponent:SetOrder(order)
  if self.node.order ~= order then
    self.node.order = order
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Sets the callback fired once this node's own `Layout()` pass is
--- resolved and clean. `nil` removes it.
--- @param onLayout? fun(component: WaffleFlexComponent, width: integer, height: integer)
function _W.FlexComponent:SetOnLayout(onLayout)
  if self.node.onLayout ~= onLayout then
    self.node.onLayout = onLayout
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Looks up a child anywhere in the tree by its `key`, erroring if none is
--- found. A duplicate key isn't validated against, the first match wins.
--- @param key string
--- @return WaffleFlexComponent
function _W.FlexComponent:GetChild(key)
  local root = _W.Ownership:FindRoot(self.node)
  local found = _W.FlexComponentFactory:FindNodeByKey(root, key)
  assert(found, "Waffle: no child registered under key '" .. key .. "'")
  return _W.FlexComponentFactory:New(found)
end

--- Returns every one of this node's own children, wrapped, in declaration
--- order, not necessarily visual `order`. Not recursive. Empty if this
--- node has none.
--- @return WaffleFlexComponent[]
function _W.FlexComponent:GetChildren()
  local children = {}
  for i, node in ipairs(self.node.children or EMPTY_CHILDREN) do
    _W.Ownership:Claim(node, self.node)
    children[i] = _W.FlexComponentFactory:New(node)
  end
  return children
end

--- Returns this node's frame, `nil` if not resolved yet, e.g. a
--- `frameFactory` not yet laid out.
--- @return WaffleFrame?
function _W.FlexComponent:GetFrame()
  return self.node.frame
end

--- Returns `true` if this node's tree has changed since its last `Layout()` call.
--- @return boolean
function _W.FlexComponent:IsDirty()
  return _W.DirtyRoots:IsDirty(_W.Ownership:FindRoot(self.node))
end

--- Removes this node from the layout flow entirely, its siblings reflow
--- to fill the space. Position in the tree is preserved, `Show()` brings
--- it back.
function _W.FlexComponent:Hide()
  if not self.node.hidden then
    self.node.hidden = true
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Reverses `Hide()`. No-ops if not currently hidden.
function _W.FlexComponent:Show()
  if self.node.hidden then
    self.node.hidden = false
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Runs the layout for the tree containing this node, starting from its
--- actual current root. No-ops unless something changed since the last
--- call, cheap to call from e.g. an `OnUpdate` handler every frame.
function _W.FlexComponent:Layout()
  local root = _W.Ownership:FindRoot(self.node)
  if _W.DirtyRoots:IsDirty(root) then
    _W.LayoutCache.currentPass = _W.LayoutCache.currentPass + 1
    local onLayoutQueue = _W.Scratch:Get()

    if root.hidden then
      if root.frame then
        root.frame:Hide()
      end
    else
      local frame = _W.Utils:ResolveFrame(root)
      frame:Show()

      -- Root resolves its own width/height the same way
      -- `_W.Sizing:ResolveDimension` resolves any child's.
      local width = _W.Sizing:ResolveDimension(root, "width")
      local height = _W.Sizing:ResolveDimension(root, "height")
      assert(width,
        "Waffle: root needs its own `width`, or `\"AUTO\"` if `direction` is ROW, nothing above it to resolve one automatically")
      assert(height,
        "Waffle: root needs its own `height`, or `\"AUTO\"` if `direction` is COLUMN, nothing above it to resolve one automatically")

      frame:SetWidth(width)
      frame:SetHeight(height)

      -- Same rule as every other node: nothing to lay out without children.
      if root.children then
        _W.FlexLayout:Layout(root, frame, width, height, root.defaultFrameFactory, onLayoutQueue)
      end

      if root.onLayout then
        _W.OnLayoutQueue:Add(onLayoutQueue, root, width, height)
      end
    end

    -- Cleared before firing, not after: a mutation `onLayout` makes below
    -- isn't wiped out along with it.
    _W.DirtyRoots:Clear(root)
    _W.OnLayoutQueue:FireAll(onLayoutQueue)
    _W.Scratch:Release(onLayoutQueue)
  end
end

-- Vivifies `self.node.children` on first use: a direct node mutation, but
-- the same kind `AddRow`/`AddColumn` already make forcing a fresh node's
-- own `direction`, since adding a child inherently needs somewhere to put it.

--- Appends `node` as a child as-is, returning its own component. Errors
--- if `node` already belongs to a different component, call
--- `DetachComponent()` on that one first to move it here. No-ops if
--- `node` is already this node's own, still returns a component.
--- @param node WaffleFlexNode
--- @return WaffleFlexComponent
function _W.FlexComponent:AddChild(node)
  if _W.Ownership:Claim(node, self.node) then
    self.node.children = self.node.children or {}
    table.insert(self.node.children, node)
    _W.DirtyRoots:Mark(self.node)
  end
  return _W.FlexComponentFactory:New(node)
end

--- Appends a new ROW child, returning it for further composition. Errors
--- if `node` already belongs to a different component, call
--- `DetachComponent()` on that one first to move it here.
--- @param node? WaffleFlexNode
--- @return WaffleFlexComponent
function _W.FlexComponent:AddRow(node)
  node = node or {}
  node.direction = "ROW"
  if _W.Ownership:Claim(node, self.node) then
    self.node.children = self.node.children or {}
    table.insert(self.node.children, node)
    _W.DirtyRoots:Mark(self.node)
  end
  return _W.FlexComponentFactory:New(node)
end

--- Appends a new COLUMN child, returning it for further composition.
--- Errors if `node` already belongs to a different component, call
--- `DetachComponent()` on that one first to move it here.
--- @param node? WaffleFlexNode
--- @return WaffleFlexComponent
function _W.FlexComponent:AddColumn(node)
  node = node or {}
  node.direction = "COLUMN"
  if _W.Ownership:Claim(node, self.node) then
    self.node.children = self.node.children or {}
    table.insert(self.node.children, node)
    _W.DirtyRoots:Mark(self.node)
  end
  return _W.FlexComponentFactory:New(node)
end

--- Grafts an already-composed `component` into this node's children,
--- as-is: its own direction, size, and structure are unchanged, unlike
--- `AddRow`/`AddColumn` which force a fresh node's direction. Errors if
--- `component` already belongs to a different one, call
--- `DetachComponent()` on that one first to move it here. No-ops if
--- `component` is already this node's own, still returns it.
--- @param component WaffleFlexComponent
--- @return WaffleFlexComponent
function _W.FlexComponent:AttachComponent(component)
  local node = component.node
  if _W.Ownership:Claim(node, self.node) then
    self.node.children = self.node.children or {}
    table.insert(self.node.children, node)
    _W.DirtyRoots:Mark(self.node)
  end
  return component
end

--- Detaches this component from its current owner, if it has one, the
--- same as calling `DetachComponent()` on that owner. Always returns
--- itself, whether or not it actually had an owner to release.
--- @return WaffleFlexComponent
function _W.FlexComponent:Detach()
  _W.Ownership:Detach(self.node)
  return self
end

--- Detaches from the tree entirely, unlike `Hide()`. Doesn't touch
--- `component`'s own `frame`.
--- @param component WaffleFlexComponent
--- @return boolean detached
function _W.FlexComponent:DetachComponent(component)
  return _W.Ownership:Detach(component.node, self.node)
end

--- Removes every child from this node, same as calling `DetachComponent`
--- on each one.
function _W.FlexComponent:Clear()
  local children = self.node.children or EMPTY_CHILDREN
  if #children == 0 then return end
  for i = #children, 1, -1 do
    local child = table.remove(children, i)
    _W.DeclarationOrder:Unassign(child)
    _W.Ownership:Release(child)
  end
  _W.DirtyRoots:Mark(self.node)
end

-- =============================================================================
-- Waffle
-- =============================================================================

--- Starts composing a `Flex` container and returns it: call
--- `AddRow`/`AddColumn`/`AddChild` to populate it, then `Layout()` to run it.
--- For a fully declarative style, `node.children` may be given directly.
--- @param node WaffleFlexNode
--- @return WaffleFlexComponent
function Waffle:Flex(node)
  _W.DirtyRoots:Mark(node)
  return _W.FlexComponentFactory:New(node)
end
