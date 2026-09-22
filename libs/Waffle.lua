-- =============================================================================
-- Waffle: 0.12.0 - https://github.com/moody/Waffle
-- =============================================================================

local _, Addon = ...
Addon.Waffle = {}

--- @class Waffle
local Waffle = Addon.Waffle

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

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
--- @alias WaffleFrame table

--- The valid `direction` values.
--- @enum (key) WaffleFlexDirection
local DIRECTIONS = { ROW = true, COLUMN = true, ROW_REVERSE = true, COLUMN_REVERSE = true }

--- The valid `align` and `alignSelf` values.
--- @enum (key) WaffleFlexAlign
local ALIGNS = { START = true, CENTER = true, END = true, STRETCH = true }

--- The valid `justify` values.
--- @enum (key) WaffleFlexJustify
local JUSTIFIES = { START = true, CENTER = true, END = true, SPACE_BETWEEN = true, SPACE_AROUND = true, SPACE_EVENLY = true }

--- The valid `visibility` values.
--- @enum (key) WaffleFlexVisibility
local VISIBILITIES = { VISIBLE = true, INVISIBLE = true, GONE = true }

--- Shared by every node in the tree, root included.
--- @class WaffleFlexNode
--- @field frame? WaffleFrame Cannot be given together with `frameFactory`. Not changeable after construction.
--- @field frameFactory? fun(parent: WaffleFrame): WaffleFrame Cannot be given together with `frame`. `parent` is `nil` for the root, nothing sits above it to pass in. Not changeable after construction.
--- @field defaultFrameFactory? fun(parent: WaffleFrame): WaffleFrame Applies to descendants only, not this node itself.
--- @field children? WaffleFlexNode[] Positioned in a row or column, per `direction`.
--- @field direction? WaffleFlexDirection Default `ROW`. `_REVERSE` keeps the same main axis, only the starting edge (and visual order along it) flips. Case insensitive, any other value throws an error.
--- @field width? integer | "AUTO" | string Always physical/horizontal, regardless of `direction`. `"AUTO"` sums this node's own children's own `width` along its main axis (`direction` is `ROW`), maxes them along its cross axis instead. A percentage string (`"50%"`) resolves against the parent's own `width`, erroring without one available (the root, or a parent whose own `width` is itself still being computed from `"AUTO"`). Has no effect on `minWidth`/`maxWidth`, same as any other fixed `width`.
--- @field height? integer | "AUTO" | string Same as `width`, vertical instead; sums along its main axis when `direction` is `COLUMN`, maxes along its cross axis otherwise, a percentage resolves against the parent's own `height`.
--- @field grow? number This node's own share of its parent's leftover main-axis space, relative to its equally-flexible siblings. Default `1`. No effect on a node with its own explicit main-axis `width`/`height`, or on the root.
--- @field shrink? number This node's own share of its parent's main-axis deficit, when its siblings' own sizes don't all fit. Weighted by this value times this node's own main-axis size, not the value alone. Default `1`; `0` never shrinks below this node's own stated size. No effect on a flexible node (nothing stated to reduce), or on the root.
--- @field align? WaffleFlexAlign Cross-axis alignment for this node's own children. Default `STRETCH`. A child's own `alignSelf` overrides this. Case insensitive, any other value throws an error.
--- @field alignSelf? WaffleFlexAlign Overrides the parent's `align`. No effect on the root. Case insensitive, any other value throws an error.
--- @field justify? WaffleFlexJustify Main-axis distribution of leftover space among this node's own children. Default `START`. No effect if any child has a positive `grow` share, it already claims the leftover space. Case insensitive, any other value throws an error.
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
--- @field visibility? WaffleFlexVisibility `"VISIBLE"` shows this node's frame. `"INVISIBLE"` hides it but keeps its space in the layout, so siblings do not reflow. `"GONE"` excludes this node from the layout entirely; siblings reflow to fill the space, and `Layout()` hides its own frame and every already-resolved frame in its subtree. An ancestor's own `visibility` affects this node's frame the same way, without changing this node's own. On the root, `"INVISIBLE"` still creates its frame and lays out the tree, use `"GONE"` to defer that until it is first shown. Case insensitive, any other value throws an error. Default `"VISIBLE"`.
--- @field key? string For lookup via `FindByKey(key)`. Duplicate keys aren't validated against, the first match wins.
--- @field order? integer Visual position among siblings, independent of declaration order. Default `0`, ties broken by declaration order. No effect on the root.
--- @field onLayout? fun(frame: WaffleFrame, width: integer, height: integer) Fires once the whole `Layout()` pass is resolved and clean, not while it's still running, bottom-up, root last. Mutating a different node from here schedules a future `Layout()` call, the same as any other setter.
--- @field onMeasure? fun(frame: WaffleFrame, width?: number, height?: number): number, number Returns the content's `width, height` when this node leaves either `"AUTO"`. Called with the sizes already known: the axis being asked is `nil`, and so is the other one if it is not known yet. Only the `"AUTO"` axis of the result is used, and `shrink` still applies afterward. Cannot be given together with `children`. May run more than once per `Layout()` pass, so it must be safe to repeat. Never called for a `"GONE"` node.

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

--- Small helpers that do not belong to a section of their own.
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
--- `defaultFrameFactory` if neither was already given, then calls the
--- callbacks waiting on a frame it created. `parent` is `nil` for the
--- root, nothing sits above it to hand a factory.
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
    _W.FrameReadyQueue:Fire(node)
  end

  return node.frame
end

--- Resolves `node.frame` like `ResolveFrame`, creating its ancestors' frames
--- first if they do not exist yet, so a node can have a frame before layout
--- reaches it. `node` and its ancestors must already have an owner recorded.
--- @param node WaffleFlexNode
--- @return WaffleFrame
function _W.Utils:EnsureFrame(node)
  if node.frame then
    return node.frame
  end

  local owners = _W.Ownership.byNode
  local parent = owners[node]
  local parentFrame = parent and self:EnsureFrame(parent)

  local defaultFrameFactory
  local ancestor = parent
  while ancestor and not defaultFrameFactory do
    defaultFrameFactory = ancestor.defaultFrameFactory
    ancestor = owners[ancestor]
  end

  return self:ResolveFrame(node, parentFrame, defaultFrameFactory)
end

--- Hides every already-resolved frame in `node`'s own subtree. A
--- `frameFactory` not yet resolved has nothing to hide, left alone.
--- @param node WaffleFlexNode
function _W.Utils:HideResolvedFrames(node)
  if node.frame then
    node.frame:Hide()
  end
  for _, child in ipairs(node.children or EMPTY_CHILDREN) do
    self:HideResolvedFrames(child)
  end
end

--- Parses an enum-style `value` against `values`, a table whose keys are
--- the valid uppercase names. Case insensitive. Errors, naming `field`, on
--- anything unrecognized.
--- @param field string
--- @param value string
--- @param values table<string, boolean>
--- @return string
function _W.Utils:ParseEnum(field, value, values)
  if values[value] then return value end

  local upper = type(value) == "string" and value:upper() or nil
  if not (upper and values[upper]) then
    local names = ""
    for name in pairs(values) do
      names = names .. " " .. name
    end
    error("Waffle: invalid `" .. field .. "` '" .. tostring(value) .. "', expected one of:" .. names, 0)
  end

  return upper
end

--- Parses `node`'s own `direction`, defaulting to `"ROW"`.
--- @param node WaffleFlexNode
--- @return boolean isRow `true` for `"ROW"`/`"ROW_REVERSE"`, `false` for `"COLUMN"`/`"COLUMN_REVERSE"`.
--- @return boolean isReverse `true` for either `_REVERSE` variant.
function _W.Utils:ParseFlexDirection(node)
  local direction = self:ParseEnum("direction", node.direction or "ROW", DIRECTIONS)
  return
      (direction == "ROW" or direction == "ROW_REVERSE"),
      (direction == "ROW_REVERSE" or direction == "COLUMN_REVERSE")
end

--- Parses a `visibility` value, defaulting to `"VISIBLE"`. Case insensitive.
--- Errors on anything unrecognized.
--- @param visibility? WaffleFlexVisibility
--- @return WaffleFlexVisibility
function _W.Utils:ParseVisibility(visibility)
  if visibility == nil then return "VISIBLE" end
  return self:ParseEnum("visibility", visibility, VISIBILITIES)
end

-- =============================================================================
-- Scratch
-- =============================================================================

--- A pool of reusable tables for short-lived use. It has no size cap.
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
-- FrameReadyQueue
-- =============================================================================

--- The `WhenFrameReady()` callbacks waiting on each node whose frame is not
--- created yet. Weak keys so an unreferenced node can still be garbage
--- collected.
_W.FrameReadyQueue = {
  byNode = setmetatable({}, { __mode = "k" })
}

--- Queues `callback` until `node`'s frame is created.
--- @param node WaffleFlexNode
--- @param callback fun(frame: WaffleFrame)
function _W.FrameReadyQueue:Add(node, callback)
  local callbacks = self.byNode[node]
  if not callbacks then
    callbacks = {}
    self.byNode[node] = callbacks
  end
  callbacks[#callbacks + 1] = callback
end

--- Calls every callback queued for `node` with its frame, in the order they
--- were added, then forgets them.
--- @param node WaffleFlexNode
function _W.FrameReadyQueue:Fire(node)
  local callbacks = self.byNode[node]
  if not callbacks then return end
  self.byNode[node] = nil
  for i = 1, #callbacks do
    callbacks[i](node.frame)
  end
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
    entry.node.onLayout(entry.node.frame, entry.width, entry.height)
    _W.Scratch:Release(entry)
  end
end

-- =============================================================================
-- Sorting
-- =============================================================================

--- Functions for ordering siblings by `order`, ties keeping their
--- existing order, and for collecting a node's visible ones in that order.
_W.Sorting = {}

--- Whether `childA` sorts before `childB`, by `order` alone. Equal values
--- do not sort before each other.
--- @param childA WaffleFlexNode
--- @param childB WaffleFlexNode
--- @return boolean
function _W.Sorting:IsFlexChildBefore(childA, childB)
  return (childA.order or 0) < (childB.order or 0)
end

--- Sorts `children` in place by `order`, ties keeping their existing
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

--- Returns `node`'s children that are not `"GONE"`, sorted by `order`, ties
--- in declaration order, and records `node` as their owner. Pooled, the caller
--- releases it with `_W.Scratch`.
--- @param node WaffleFlexNode
--- @return WaffleFlexNode[]
function _W.Sorting:GetVisibleChildren(node)
  --- @type WaffleFlexNode[]
  local visibleChildren = _W.Scratch:Get()
  local children = node.children or EMPTY_CHILDREN
  local count = 0

  for i = 1, #children do
    local child = children[i]
    if _W.Utils:ParseVisibility(child.visibility) ~= "GONE" then
      if _W.Ownership.byNode[child] ~= node then
        _W.Ownership:Claim(child, node)
      end
      count = count + 1
      visibleChildren[count] = child
    end
  end

  self:SortFlexChildren(visibleChildren)
  return visibleChildren
end

-- =============================================================================
-- LayoutCache
-- =============================================================================

--- Per-pass memo of `"AUTO"` sizes for `Layout()`.
_W.LayoutCache = {}

--- Bumped once per `Layout()` pass (see `FlexComponent:Layout()`).
--- Scopes `resolvedDimensions` entries to the pass that computed them,
--- so a stale one from an earlier pass is never reused.
_W.LayoutCache.currentPass = 0

--- `node`'s own `"AUTO"` result per axis, with the known other-axis size it
--- was computed for, tagged with the pass that computed it. Weak keys so an
--- unreferenced node can still be garbage collected.
_W.LayoutCache.resolvedDimensions = setmetatable({}, { __mode = "k" })

--- The field of a `resolvedDimensions` entry holding the known other-axis
--- size that `axis`'s result was computed for.
--- @type table<"width" | "height", string>
local KNOWN_SIZE_FIELDS = { width = "widthKnownSize", height = "heightKnownSize" }

--- Returns `node`'s cached `"AUTO"` result for `axis`, `nil` if it was
--- never computed, is from a stale pass, or was computed for a different
--- `knownOtherAxisSize`.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param knownOtherAxisSize? integer
--- @return integer?
function _W.LayoutCache:GetResolvedDimension(node, axis, knownOtherAxisSize)
  local entry = self.resolvedDimensions[node]
  if entry and entry.pass == self.currentPass and entry[KNOWN_SIZE_FIELDS[axis]] == knownOtherAxisSize then
    return entry[axis]
  end
  return nil
end

--- Records `node`'s `"AUTO"` result for `axis`, computed for
--- `knownOtherAxisSize`, for the rest of the current pass. Reuses `node`'s
--- own existing entry rather than allocating a new one, resetting it first
--- if it's from a stale pass. A later result for another
--- `knownOtherAxisSize` replaces this one.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param knownOtherAxisSize? integer
--- @param value integer
function _W.LayoutCache:SetResolvedDimension(node, axis, knownOtherAxisSize, value)
  local entry = self.resolvedDimensions[node]
  if not entry then
    entry = { pass = self.currentPass }
    self.resolvedDimensions[node] = entry
  elseif entry.pass ~= self.currentPass then
    entry.pass = self.currentPass
    entry.width = nil
    entry.height = nil
    entry.widthKnownSize = nil
    entry.heightKnownSize = nil
  end
  entry[axis] = value
  entry[KNOWN_SIZE_FIELDS[axis]] = knownOtherAxisSize
end

-- =============================================================================
-- SpaceDistributor
-- =============================================================================

--- Functions that resolve how much of a line's leftover main-axis space or
--- deficit each constrained child gets. Each round freezes whichever child
--- hits its min/max bound and shares the rest among the others. `Grow`
--- grows children up from `0`, `Shrink` shrinks them down from a stated
--- size.
_W.SpaceDistributor = {}

--- A size, per child.
--- @alias WaffleFlexNodeSizes table<WaffleFlexNode, number>

--- What `Distribute` needs from `GrowStrategy` and `ShrinkStrategy`.
--- @class WaffleSpaceDistributorStrategy
--- @field weight fun(child: WaffleFlexNode, statedSizes?: WaffleFlexNodeSizes): number
--- @field toCandidate fun(child: WaffleFlexNode, share: number, statedSizes?: WaffleFlexNodeSizes): number
--- @field toConsumed fun(child: WaffleFlexNode, clamped: number, statedSizes?: WaffleFlexNodeSizes): number

--- For `Grow`, a child's share is its candidate size. For `Shrink`, the
--- candidate is its stated size minus its share.
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

--- Distributes `mainAxisSpace` among `constrained` children in proportion to
--- `strategy.weight`, clamping each child's candidate size
--- (`strategy.toCandidate`) to `minField`/`maxField`. A clamped child is
--- frozen, and the rounds repeat until one freezes nobody new.
--- @param constrained WaffleFlexNode[] Only children with `minField` or `maxField` set, the caller filters out the rest.
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
--- @param constrained WaffleFlexNode[] See `Distribute`.
--- @param mainAxisSpace number Leftover main-axis space to give out.
--- @param totalWeight number Sum of every `constrained` child's own `grow` (default `1`).
--- @param minField "minWidth" | "minHeight"
--- @param maxField? "maxWidth" | "maxHeight"
--- @return WaffleFlexNodeSizes? frozen See `Distribute`.
--- @return number mainAxisSpace See `Distribute`.
--- @return number totalWeight See `Distribute`.
function _W.SpaceDistributor:Grow(constrained, mainAxisSpace, totalWeight, minField, maxField)
  return self:Distribute(constrained, mainAxisSpace, totalWeight, minField, maxField, self.GrowStrategy)
end

--- Distributes a main-axis deficit among fixed/percentage children, each
--- shrinking down from its own stated size in `statedSizes`, clamped to
--- `minField`. `maxField` never applies, a child only ever shrinks down
--- from it, never up past it.
--- @param constrained WaffleFlexNode[] Only children with `minField` set, the caller filters out the rest.
--- @param mainAxisSpace number Main-axis deficit to claim back.
--- @param totalWeight number Sum of every `constrained` child's own `shrink` (default `1`) times its own stated size.
--- @param minField "minWidth" | "minHeight"
--- @param statedSizes WaffleFlexNodeSizes Each `constrained` child's own already-resolved size; `shrink`'s own weight formula needs it every round, not just once.
--- @return WaffleFlexNodeSizes? frozen See `Distribute`.
--- @return number mainAxisSpace See `Distribute`.
--- @return number totalWeight See `Distribute`.
function _W.SpaceDistributor:Shrink(constrained, mainAxisSpace, totalWeight, minField, statedSizes)
  return self:Distribute(constrained, mainAxisSpace, totalWeight, minField, nil, self.ShrinkStrategy, statedSizes)
end

-- =============================================================================
-- Sizing
-- =============================================================================

--- Functions for resolving a node's own size along an axis (fixed,
--- percentage, or `"AUTO"`), and clamping a computed size to a node's
--- own `min`/`max`. `ResolveDimension` is the entry point. It sends
--- `"AUTO"` to `ComputeAutoMainSize` (sum of the children) along the
--- node's own main axis, and to `ComputeAutoCrossSize` (max of the
--- children, or of each wrapped line) along its cross axis. Splitting
--- children into wrapped lines (`SplitFlexLines`) and sharing a line's
--- main-axis space out (`ResolveLineSizes`) are sizing too, so they live
--- here, for computing `"AUTO"` sizes and for layout alike.
_W.Sizing = {}

--- The per-side field names of each box value, per axis, as
--- `{ leading, trailing }`.
local BOX_SIDES = {
  padding = { width = { "paddingLeft", "paddingRight" }, height = { "paddingTop", "paddingBottom" } },
  margin = { width = { "marginLeft", "marginRight" }, height = { "marginTop", "marginBottom" } },
}

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
  local sides = BOX_SIDES[prefix][axis]
  return node[sides[1]] or shorthand, node[sides[2]] or shorthand
end

--- The parent size a percentage on `axis` resolves against, `nil` if unknown.
--- @param axis "width" | "height"
--- @param parentWidth? integer
--- @param parentHeight? integer
--- @return integer?
function _W.Sizing:ResolveParentSize(axis, parentWidth, parentHeight)
  if axis == "width" then
    return parentWidth
  end
  return parentHeight
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

--- The size `child` takes along `axis` when its parent stretches it
--- across `contentCrossSize`: what is left after its own `margin`, clamped to
--- its own `min`/`max`.
--- @param child WaffleFlexNode
--- @param axis "width" | "height"
--- @param contentCrossSize integer
--- @return integer
function _W.Sizing:ResolveStretchedSize(child, axis, contentCrossSize)
  local leading, trailing = self:ResolveBoxAxis(child, axis, "margin")
  local isWidth = axis == "width"
  return self:ClampSize(child, contentCrossSize - leading - trailing, isWidth and "minWidth" or "minHeight",
    isWidth and "maxWidth" or "maxHeight")
end

--- Like `ResolveDimension`, but `nil` instead of computing an `"AUTO"`
--- or erroring on a percentage with no parent size to resolve against.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param parentWidth? integer
--- @param parentHeight? integer
--- @return integer?
function _W.Sizing:ResolveKnownDimension(node, axis, parentWidth, parentHeight)
  local value = node[axis]
  local parentSize = self:ResolveParentSize(axis, parentWidth, parentHeight)
  if value == "AUTO" or (type(value) == "string" and not parentSize) then
    return nil
  end
  return self:ResolveDimension(node, axis, parentWidth, parentHeight)
end

--- Resolves `node`'s size along `axis`: the given number, a percentage of
--- `parentWidth`/`parentHeight` (whichever matches `axis`), computed from
--- its own children if `"AUTO"` (a sum along `node`'s own main axis, a max
--- along its cross axis, or from its `onMeasure`), or `nil` if `node` is flexible along `axis`
--- instead. An `"AUTO"` result is cached for the rest of the current
--- pass for the `knownOtherAxisSize` it was computed for.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param parentWidth? integer Needed only if `node`'s own `width` needs it: directly, if `width` is a percentage, or indirectly, if a cross-axis `"AUTO"` needs `width` resolved as a step first.
--- @param parentHeight? integer Same as `parentWidth`, for `height`.
--- @param knownOtherAxisSize? integer `node`'s exact size along the other axis, when the caller already knows it and `node` has none of its own. Only used to compute `"AUTO"`: a wrapping node wraps against it.
--- @return integer?
function _W.Sizing:ResolveDimension(node, axis, parentWidth, parentHeight, knownOtherAxisSize)
  local value = node[axis]

  if type(value) ~= "string" then
    return value
  end

  if value == "AUTO" then
    local cached = _W.LayoutCache:GetResolvedDimension(node, axis, knownOtherAxisSize)
    if cached == nil then
      if node.onMeasure then
        cached = self:ComputeMeasuredSize(node, axis, parentWidth, parentHeight, knownOtherAxisSize)
      elseif _W.Utils:ParseFlexDirection(node) == (axis == "width") then
        cached = self:ComputeAutoMainSize(node, axis, parentWidth, parentHeight, knownOtherAxisSize)
      else
        cached = self:ComputeAutoCrossSize(node, axis, parentWidth, parentHeight, knownOtherAxisSize)
      end
      _W.LayoutCache:SetResolvedDimension(node, axis, knownOtherAxisSize, cached)
    end
    return cached
  end

  local number = value:match("^(%d+%.?%d*)%%$")
  number = number and tonumber(number)
  if not number then
    error("Waffle: `" .. axis .. "` must be a number, `\"AUTO\"`, or a percentage string like `\"50%\"`, got `" ..
      value .. "`", 0)
  end

  local parentSize = self:ResolveParentSize(axis, parentWidth, parentHeight)
  if not parentSize then
    error("Waffle: `" .. axis .. "` given as a percentage needs a resolvable parent `" ..
      axis .. "` to size against; none here, either this is the root or the parent's own `" ..
      axis .. "` is itself still being computed", 0)
  end

  return parentSize * (number / 100)
end

--- `child`'s outer size along `axis`, `nil` if it is flexible there.
--- @param child WaffleFlexNode
--- @param axis "width" | "height"
--- @param knownOtherAxisSize? integer See `ResolveDimension`.
--- @return integer?
function _W.Sizing:ResolveOuterSize(child, axis, knownOtherAxisSize)
  local size = self:ResolveDimension(child, axis, nil, nil, knownOtherAxisSize)
  if not size then
    return nil
  end
  local leading, trailing = self:ResolveBoxAxis(child, axis, "margin")
  return size + leading + trailing
end

--- Resolves `child`'s size along `axis`, its parent's main axis, when the
--- parent stretches `child` across `contentCrossSize` on the other axis.
--- `contentCrossSize` is `nil` while the parent's own cross size is unknown.
--- @param child WaffleFlexNode
--- @param axis "width" | "height"
--- @param parentWidth? integer
--- @param parentHeight? integer
--- @param contentCrossSize? integer
--- @return integer?
function _W.Sizing:ResolveChildMainSize(child, axis, parentWidth, parentHeight, contentCrossSize)
  local value = child[axis]
  if value == "AUTO" then
    local knownOtherAxisSize
    if contentCrossSize then
      knownOtherAxisSize = self:ResolveStretchedSize(child, axis == "width" and "height" or "width", contentCrossSize)
    end
    return self:ResolveDimension(child, axis, parentWidth, parentHeight, knownOtherAxisSize)
  end
  if type(value) ~= "string" then
    return value
  end
  return self:ResolveDimension(child, axis, parentWidth, parentHeight)
end

--- Asks `node.onMeasure` for `node`'s size along `axis`, passing the size of
--- the other axis when it is known: `node`'s own, or `knownOtherAxisSize`.
--- The frame is created first if layout has not reached it yet. Errors if
--- `node` has `children`, or `onMeasure` returns no number for `axis`.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param parentWidth? integer Needed only if `node`'s own other axis is a percentage.
--- @param parentHeight? integer Same as `parentWidth`, for `height`.
--- @param knownOtherAxisSize? integer See `ResolveDimension`.
--- @return number
function _W.Sizing:ComputeMeasuredSize(node, axis, parentWidth, parentHeight, knownOtherAxisSize)
  assert(not (node.children and #node.children > 0), "Waffle: a node with `onMeasure` cannot have `children`")

  local isWidth = axis == "width"
  local otherAxis = isWidth and "height" or "width"
  local otherSize = self:ResolveKnownDimension(node, otherAxis, parentWidth, parentHeight) or knownOtherAxisSize

  local frame = _W.Utils:EnsureFrame(node)
  local width, height
  if isWidth then
    width, height = node.onMeasure(frame, nil, otherSize)
  else
    width, height = node.onMeasure(frame, otherSize, nil)
  end

  local size = isWidth and width or height
  if type(size) ~= "number" then
    error("Waffle: `onMeasure` must return the `width` and `height` as numbers, got `" .. tostring(size) ..
      "` for `" .. axis .. "`", 0)
  end
  return size
end

--- Computes `node`'s size along its own main axis (`axis`) as the sum of
--- its children's own outer sizes (own size plus `margin`) along that
--- same axis, plus `gap` between them and padding on each end. Errors if
--- any visible child is flexible, there's no space yet for it to split.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param parentWidth? integer Needed only if `node`'s own other axis is a percentage.
--- @param parentHeight? integer Same as `parentWidth`, for `height`.
--- @param knownOtherAxisSize? integer See `ResolveDimension`.
--- @return integer
function _W.Sizing:ComputeAutoMainSize(node, axis, parentWidth, parentHeight, knownOtherAxisSize)
  assert(node.children, "Waffle: `\"AUTO\"` needs `children` to compute a size from")

  local gap = node.gap or 0
  local total = 0

  local crossAxis = axis == "width" and "height" or "width"
  local crossLeading, crossTrailing = self:ResolveBoxAxis(node, crossAxis, "padding")
  local crossSize = self:ResolveKnownDimension(node, crossAxis, parentWidth, parentHeight) or knownOtherAxisSize
  local contentCrossSize = crossSize and (crossSize - crossLeading - crossTrailing)

  local visibleChildren = _W.Sorting:GetVisibleChildren(node)
  for i = 1, #visibleChildren do
    local child = visibleChildren[i]
    local size = self:ResolveChildMainSize(child, axis, nil, nil, contentCrossSize)
    if not size then
      error("Waffle: every child of an `\"AUTO\"` node that is not `\"GONE\"` needs its own `" ..
        axis .. "`, a flexible child (`nil`) has nothing to split, there's no space yet to split", 0)
    end
    local leading, trailing = self:ResolveBoxAxis(child, axis, "margin")
    total = total + size + leading + trailing
  end

  local leading, trailing = self:ResolveBoxAxis(node, axis, "padding")
  local autoMainSize = total + gap * math.max(#visibleChildren - 1, 0) + leading + trailing

  _W.Scratch:Release(visibleChildren)

  return autoMainSize
end

--- Computes `node`'s size along its own cross axis (`axis`) as the sum
--- of every line's own tallest child (`ComputeAutoLineCrossSize`), plus
--- `lineGap` between lines and padding on each end. One line, a flat max
--- with no gap term, unless `node.wrap` is set and its own main size is
--- known to wrap against.
--- @param node WaffleFlexNode
--- @param axis "width" | "height"
--- @param parentWidth? integer Needed only if `node`'s own main axis is itself a percentage.
--- @param parentHeight? integer Same as `parentWidth`, for `height`.
--- @param knownOtherAxisSize? integer See `ResolveDimension`.
--- @return integer
function _W.Sizing:ComputeAutoCrossSize(node, axis, parentWidth, parentHeight, knownOtherAxisSize)
  assert(node.children, "Waffle: `\"AUTO\"` needs `children` to compute a cross size from")

  local gap = node.gap or 0
  local lineGap = node.lineGap or gap

  local mainAxis = axis == "width" and "height" or "width"
  local mainLeading, mainTrailing = self:ResolveBoxAxis(node, mainAxis, "padding")
  local mainSize = self:ResolveKnownDimension(node, mainAxis, parentWidth, parentHeight) or knownOtherAxisSize
  local contentMainSize = mainSize and (mainSize - mainLeading - mainTrailing)

  local visibleChildren = _W.Sorting:GetVisibleChildren(node)

  -- Without a main size there is nothing to wrap against or to share out,
  -- so `visibleChildren` is the one and only line.
  --- @type WaffleFlexNode[][]?
  local lines
  if node.wrap and contentMainSize then
    -- The cross size is what is being computed here, so a child's own
    -- percentage along it errors.
    lines = _W.Sizing:SplitFlexLines(visibleChildren, mainAxis, contentMainSize, nil, gap)
  end

  local total, lineCount = 0, 0
  if lines then
    lineCount = #lines
    for i = 1, lineCount do
      total = total + self:ComputeAutoLineCrossSize(lines[i], axis, mainAxis, contentMainSize, gap)
    end
    _W.Sizing:ReleaseLines(lines)
  else
    total = self:ComputeAutoLineCrossSize(visibleChildren, axis, mainAxis, contentMainSize, gap)
    lineCount = 1
  end

  _W.Scratch:Release(visibleChildren)

  local leading, trailing = self:ResolveBoxAxis(node, axis, "padding")
  return total + lineGap * math.max(lineCount - 1, 0) + leading + trailing
end

--- The cross size of one line of `lineChildren` along `axis`, the tallest of
--- them, once their own main-axis space is shared out across
--- `contentMainSize`. Sharing out only happens when some child's own `axis`
--- is `"AUTO"`, since only then does its main size change the answer.
--- Without `contentMainSize`, a child with a flexible main size has no size to
--- base its cross size on.
--- @param lineChildren WaffleFlexNode[]
--- @param axis "width" | "height"
--- @param mainAxis "width" | "height"
--- @param contentMainSize? integer
--- @param gap integer
--- @return integer
function _W.Sizing:ComputeAutoLineCrossSize(lineChildren, axis, mainAxis, contentMainSize, gap)
  local dependsOnMainSize = false
  for i = 1, #lineChildren do
    if lineChildren[i][axis] == "AUTO" then
      dependsOnMainSize = true
      break
    end
  end

  if not (contentMainSize and dependsOnMainSize) then
    return self:MaxOuterSize(lineChildren, axis)
  end

  local mainSizes = _W.Sizing:ResolveLineSizes(lineChildren, mainAxis, contentMainSize, nil, gap)
  local size = self:MaxOuterSize(lineChildren, axis, mainSizes)
  _W.Scratch:Release(mainSizes)
  return size
end

--- The max of every one of `children`'s own outer sizes (own size plus
--- `margin`) along `axis`. Errors if any is flexible, it has no size of its
--- own. The strict counterpart to `LineCrossSize`, which falls back instead.
--- @param children WaffleFlexNode[]
--- @param axis "width" | "height"
--- @param mainSizes? WaffleFlexNodeSizes Each of `children`'s own main-axis size, for a child whose own cross size depends on it. `nil` if not known yet.
--- @return integer
function _W.Sizing:MaxOuterSize(children, axis, mainSizes)
  local max = 0
  for i = 1, #children do
    local child = children[i]
    local size = self:ResolveOuterSize(child, axis, mainSizes and mainSizes[child])
    if not size then
      error("Waffle: every child of an `\"AUTO\"` node that is not `\"GONE\"` needs its own `" ..
        axis .. "`, a flexible child (`nil`) has nothing of its own to measure", 0)
    end
    max = math.max(max, size)
  end
  return max
end

--- A line's own cross-size: the max of every child's own outer size (own
--- size plus `margin`) along `axis` that has one, skipping any that
--- don't (e.g. a `STRETCH` child on its cross axis) rather than
--- erroring. `fallback` covers a line with nothing explicit at all.
--- @param children WaffleFlexNode[]
--- @param axis "width" | "height"
--- @param fallback integer
--- @param mainSizes WaffleFlexNodeSizes Each of `children`'s own main-axis size, for a child whose own cross size depends on it.
--- @return integer
function _W.Sizing:LineCrossSize(children, axis, fallback, mainSizes)
  local max
  for i = 1, #children do
    local child = children[i]
    local size = self:ResolveOuterSize(child, axis, mainSizes[child])
    if size then
      max = max and math.max(max, size) or size
    end
  end
  return max or fallback
end

--- Splits `children` (already sorted, already visible-only) into lines
--- along `axis`: each line is as many children as fit within `contentMainSize`,
--- in order, counting each child's own `margin` as part of its size. A
--- fixed-size child that would overflow the current line starts a new
--- one instead, unless the current line is still empty, a lone child
--- bigger than `contentMainSize` still gets placed on one rather than looping
--- forever. A flexible child (no fixed size of its own yet) always joins
--- the current line, there's nothing of its own yet to check for
--- overflow, though its `margin` still counts toward the running total.
--- @param children WaffleFlexNode[]
--- @param axis "width" | "height"
--- @param contentMainSize integer
--- @param contentCrossSize? integer The parent's content cross size, if known yet; needed only for a child's own percentage/`"AUTO"` along that axis. `nil` from `ComputeAutoCrossSize`, where the node's own cross size is what is being computed.
--- @param gap integer
--- @return WaffleFlexNode[][] lines Pooled, `lines` itself and every line in it; the caller releases them with `ReleaseLines`.
function _W.Sizing:SplitFlexLines(children, axis, contentMainSize, contentCrossSize, gap)
  --- @type WaffleFlexNode[][]
  local lines = _W.Scratch:Get()
  --- @type WaffleFlexNode[]
  local currentLine = _W.Scratch:Get()
  local currentLineTotal = 0

  local parentWidth = axis == "width" and contentMainSize or contentCrossSize
  local parentHeight = axis == "height" and contentMainSize or contentCrossSize

  for i = 1, #children do
    local child = children[i]
    local size = _W.Sizing:ResolveChildMainSize(child, axis, parentWidth, parentHeight, contentCrossSize)
    local marginLeading, marginTrailing = _W.Sizing:ResolveBoxAxis(child, axis, "margin")
    local margin = marginLeading + marginTrailing
    local outerSize = size and (size + margin)

    if outerSize and #currentLine > 0 and currentLineTotal + gap + outerSize > contentMainSize then
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

--- Returns `lines`, and every line in it, to the pool.
--- @param lines WaffleFlexNode[][]
function _W.Sizing:ReleaseLines(lines)
  for _, lineChildren in ipairs(lines) do
    _W.Scratch:Release(lineChildren)
  end
  _W.Scratch:Release(lines)
end

--- Resolves every one of `lineChildren`'s own main-axis size. A fixed or
--- percentage child keeps its own stated size unless the line overflows
--- (a deficit, `shrink` gives some back), and a flexible child takes its
--- `grow` share of the leftover space. A child with a `min`/`max` goes
--- through `_W.SpaceDistributor:Grow` for flexible children (growing up
--- from `0`, clamped to `min`/`max`) or `_W.SpaceDistributor:Shrink` for
--- fixed/percentage ones (shrinking down from each one's own stated
--- size, clamped to `min`, weighted by `shrink` times that size, not
--- `shrink` alone).
--- @param lineChildren WaffleFlexNode[]
--- @param mainAxis "width" | "height"
--- @param contentMainSize integer
--- @param contentCrossSize? integer Needed only for a child's own percentage/`"AUTO"` along the cross axis.
--- @param gap integer
--- @return WaffleFlexNodeSizes mainSizes Every child's size; pooled, `LayoutFlexLine` releases it once done, not this function.
--- @return number freeSpace Space no child claimed after every size and `margin`, for `justify`. `0` whenever a flexible child takes the leftover space, or there's a deficit.
function _W.Sizing:ResolveLineSizes(lineChildren, mainAxis, contentMainSize, contentCrossSize, gap)
  local isRow = mainAxis == "width"
  local minField = isRow and "minWidth" or "minHeight"
  local maxField = isRow and "maxWidth" or "maxHeight"
  local visibleCount = #lineChildren

  local parentWidth = isRow and contentMainSize or contentCrossSize
  local parentHeight = isRow and contentCrossSize or contentMainSize

  local fixedTotal = 0
  local totalGrow = 0
  local totalShrink = 0

  --- @type WaffleFlexNode[]
  local growConstrained
  --- @type WaffleFlexNode[]
  local shrinkConstrained
  -- Holds each fixed/percentage child's stated size first, then every
  -- child's final size. `Shrink` needs the stated sizes on every round.
  --- @type WaffleFlexNodeSizes
  local mainSizes = _W.Scratch:Get()
  for i = 1, #lineChildren do
    local child = lineChildren[i]
    local marginLeading, marginTrailing = _W.Sizing:ResolveBoxAxis(child, mainAxis, "margin")
    fixedTotal = fixedTotal + marginLeading + marginTrailing

    local size = _W.Sizing:ResolveChildMainSize(child, mainAxis, parentWidth, parentHeight, contentCrossSize)
    if size then
      fixedTotal = fixedTotal + size
      totalShrink = totalShrink + (child.shrink or 1) * size
      mainSizes[child] = size
      if child[minField] then
        shrinkConstrained = shrinkConstrained or _W.Scratch:Get()
        shrinkConstrained[#shrinkConstrained + 1] = child
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
  local rawRemaining = contentMainSize - fixedTotal - totalGap
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
      mainSizes)
  end

  -- Resolve each child's final size after grow/shrink
  for i = 1, #lineChildren do
    local child = lineChildren[i]
    local size = mainSizes[child]
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
    mainSizes[child] = size
  end

  _W.Scratch:Release(growConstrained)
  _W.Scratch:Release(shrinkConstrained)
  _W.Scratch:Release(clampedSizes)
  _W.Scratch:Release(shrunkSizes)

  return mainSizes, totalGrow > 0 and 0 or remaining
end

-- =============================================================================
-- FlexLayout
-- =============================================================================

--- Functions that position `node.children` in a row or column,
--- splitting into wrapped lines first when needed. `Layout` handles one
--- node's children as one line, or several under `wrap`, and calls
--- `LayoutFlexLine` on each. `LayoutFlexLine` resolves the line's
--- main-axis sizes with `ResolveLineSizes`, then places each child and
--- calls `Layout` on the child's own children.
_W.FlexLayout = {}

--- Resolves `node.justify`'s main-axis offset/gap for one line.
--- @param node WaffleFlexNode
--- @param freeSpace number
--- @param visibleCount integer
--- @param isReverse boolean If true, swaps `START`/`END`, since the packing math itself has no other way to know the main-start edge moved. `CENTER`/`SPACE_*` need no such swap, already symmetric.
--- @return number justifyOffset
--- @return number justifyGap
function _W.FlexLayout:ResolveLineJustify(node, freeSpace, visibleCount, isReverse)
  local justify = _W.Utils:ParseEnum("justify", node.justify or "START", JUSTIFIES)

  local justifyOffset, justifyGap = 0, 0
  if isReverse then
    if justify == "START" then
      justify = "END"
    elseif justify == "END" then
      justify = "START"
    end
  end

  if justify == "END" then
    justifyOffset = freeSpace
  elseif justify == "CENTER" then
    justifyOffset = freeSpace / 2
  elseif justify == "SPACE_BETWEEN" and visibleCount > 1 then
    justifyGap = freeSpace / (visibleCount - 1)
  elseif justify == "SPACE_AROUND" and visibleCount > 0 then
    justifyGap = freeSpace / visibleCount
    justifyOffset = justifyGap / 2
  elseif justify == "SPACE_EVENLY" then
    justifyGap = freeSpace / (visibleCount + 1)
    justifyOffset = justifyGap
  end

  return justifyOffset, justifyGap
end

--- Creates `child`'s frame if it does not exist yet, then parents it to
--- `frame`, clears its points, and shows or hides it per its own
--- `visibility`.
--- @param child WaffleFlexNode
--- @param frame WaffleFrame
--- @param defaultFrameFactory? fun(parent: WaffleFrame): WaffleFrame
--- @return WaffleFrame childFrame
function _W.FlexLayout:PrepareChildFrame(child, frame, defaultFrameFactory)
  local childFrame = _W.Utils:ResolveFrame(child, frame, defaultFrameFactory)

  if _W.Utils:ParseVisibility(child.visibility) == "INVISIBLE" then
    childFrame:Hide()
  else
    childFrame:Show()
  end
  childFrame:ClearAllPoints()
  childFrame:SetParent(frame)

  return childFrame
end

--- Resolves `child`'s own cross-axis size and its offset along the cross
--- axis, per its `alignSelf` (or `node.align`). Non-`STRETCH` alignment
--- requires the child's own cross-axis value, it never falls back to
--- stretching; `STRETCH` itself clamps to the child's own cross-axis
--- `min`/`max`, if either is set. The child's own `margin` insets it
--- from `crossStart`.
--- @param node WaffleFlexNode
--- @param child WaffleFlexNode
--- @param crossAxis "width" | "height"
--- @param lineCrossSize integer
--- @param crossStart integer
--- @param parentWidth integer
--- @param parentHeight integer
--- @param childMainSize integer `child`'s own already-resolved main-axis size.
--- @return integer childCrossSize
--- @return number crossOffset
function _W.FlexLayout:AlignChild(node, child, crossAxis, lineCrossSize, crossStart, parentWidth, parentHeight,
                                  childMainSize)
  local isWidth = crossAxis == "width"
  local marginLeading, marginTrailing = _W.Sizing:ResolveBoxAxis(child, crossAxis, "margin")

  local align
  if child.alignSelf ~= nil then
    align = _W.Utils:ParseEnum("alignSelf", child.alignSelf, ALIGNS)
  else
    align = _W.Utils:ParseEnum("align", node.align or "STRETCH", ALIGNS)
  end

  local childCrossSize = _W.Sizing:ResolveDimension(child, crossAxis, parentWidth, parentHeight, childMainSize)
  if not childCrossSize then
    if align ~= "STRETCH" then
      error("Waffle: a child aligned '" ..
        align ..
        "' (not 'STRETCH') needs its own `" ..
        crossAxis .. "`, alignment doesn't fall back to the container's cross size", 0)
    end
    childCrossSize = _W.Sizing:ClampSize(child, lineCrossSize - marginLeading - marginTrailing,
      isWidth and "minWidth" or "minHeight", isWidth and "maxWidth" or "maxHeight")
  end

  local crossOffset = crossStart + marginLeading
  if align == "CENTER" or align == "END" then
    local leftover = lineCrossSize - (childCrossSize + marginLeading + marginTrailing)
    crossOffset = crossStart + (align == "CENTER" and leftover / 2 or leftover) + marginLeading
  end

  return childCrossSize, crossOffset
end

--- Positions `lineChildren` along `mainAxis`, starting at `mainStart`, and
--- aligns each within its line's cross size, starting at `crossStart`. One
--- line is every one of `node.children` when `node.wrap` isn't set, or one
--- wrapped line's worth of them when it is. Each child's `margin` insets it
--- from wherever it would otherwise sit, on both axes.
--- @param node WaffleFlexNode
--- @param frame WaffleFrame
--- @param lineChildren WaffleFlexNode[]
--- @param mainAxis "width" | "height"
--- @param crossAxis "width" | "height"
--- @param isReverse boolean If true, `lineChildren` arrives already reversed by the caller.
--- @param contentMainSize integer
--- @param contentCrossSize integer The parent's content cross size.
--- @param mainStart integer
--- @param crossStart integer
--- @param defaultFrameFactory? fun(parent: WaffleFrame): WaffleFrame
--- @param onLayoutQueue table Passed through to a `children` recursion; a visited child's own `onLayout` (if any) is queued onto it, not fired yet.
--- @return integer lineCrossSize `contentCrossSize`, or under `wrap` the line's tallest child.
function _W.FlexLayout:LayoutFlexLine(node, frame, lineChildren, mainAxis, crossAxis, isReverse, contentMainSize,
                                      contentCrossSize, mainStart, crossStart, defaultFrameFactory, onLayoutQueue)
  local gap = node.gap or 0
  local isRow = mainAxis == "width"
  local visibleCount = #lineChildren

  local mainSizes, freeSpace = _W.Sizing:ResolveLineSizes(lineChildren, mainAxis, contentMainSize, contentCrossSize,
    gap)
  local lineCrossSize = contentCrossSize
  if node.wrap then
    lineCrossSize = _W.Sizing:LineCrossSize(lineChildren, crossAxis, contentCrossSize, mainSizes)
  end

  local parentWidth = isRow and contentMainSize or lineCrossSize
  local parentHeight = isRow and lineCrossSize or contentMainSize

  local justifyOffset, justifyGap = self:ResolveLineJustify(node, freeSpace, visibleCount, isReverse)

  local mainOffset = mainStart + justifyOffset
  for i = 1, #lineChildren do
    local child = lineChildren[i]
    local childFrame = self:PrepareChildFrame(child, frame, defaultFrameFactory)

    local childMainSize = mainSizes[child]
    local childCrossSize, crossOffset = self:AlignChild(node, child, crossAxis, lineCrossSize, crossStart,
      parentWidth, parentHeight, childMainSize)

    local marginLeading, marginTrailing = _W.Sizing:ResolveBoxAxis(child, mainAxis, "margin")
    local childMainOffset = mainOffset + marginLeading
    local childWidth, childHeight

    if isRow then
      childWidth, childHeight = childMainSize, childCrossSize
      childFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", childMainOffset, -crossOffset)
    else
      childWidth, childHeight = childCrossSize, childMainSize
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

    mainOffset = mainOffset + marginLeading + childMainSize + marginTrailing + gap + justifyGap
  end

  -- Pooled by `ResolveLineSizes`, released once the loop is done with it
  _W.Scratch:Release(mainSizes)

  return lineCrossSize
end

--- Positions `node.children` in a row or column within `frame`, sized to
--- `width`/`height`, one line (`node.wrap` unset) or several (`node.wrap`
--- set, overflowing children start a new one instead of continuing past
--- `contentMainSize`). `frame` must already be resolved/sized by the caller.
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

  local contentMainSize = (isRow and width or height) - mainLeading - mainTrailing
  local contentCrossSize = (isRow and height or width) - crossLeading - crossTrailing

  -- Ownership is claimed here, not in its own pass, since this loop is
  -- already walking every child anyway. `"GONE"` children, own subtree
  -- included, are hidden here, once.
  for i = 1, #node.children do
    local child = node.children[i]
    _W.Ownership:Claim(child, node)
    if _W.Utils:ParseVisibility(child.visibility) == "GONE" then
      _W.Utils:HideResolvedFrames(child)
    end
  end

  -- Only visible children are split into lines and laid out. Pooled,
  -- released below.
  local visibleChildren = _W.Sorting:GetVisibleChildren(node)

  if node.wrap then
    local gap = node.gap or 0
    local lineGap = node.lineGap or gap
    local crossOffset = crossLeading

    -- Pooled, from `SplitFlexLines`. Released below: `lineChildren` once
    -- its own line is done, `lines` once every line is.
    --- @type WaffleFlexNode[][]
    local lines = _W.Sizing:SplitFlexLines(visibleChildren, mainAxis, contentMainSize, contentCrossSize, gap)
    for _, lineChildren in ipairs(lines) do
      if isReverse then
        _W.Utils:ReverseArray(lineChildren)
      end

      local lineCrossSize = self:LayoutFlexLine(node, frame, lineChildren, mainAxis, crossAxis, isReverse,
        contentMainSize, contentCrossSize, mainLeading, crossOffset, defaultFrameFactory, onLayoutQueue)
      crossOffset = crossOffset + lineCrossSize + lineGap

      _W.Scratch:Release(lineChildren)
    end
    _W.Scratch:Release(lines)
  else
    if isReverse then
      _W.Utils:ReverseArray(visibleChildren)
    end

    self:LayoutFlexLine(node, frame, visibleChildren, mainAxis, crossAxis, isReverse, contentMainSize,
      contentCrossSize, mainLeading, crossLeading, defaultFrameFactory, onLayoutQueue)
  end

  _W.Scratch:Release(visibleChildren)
end

-- =============================================================================
-- FlexComponent
-- =============================================================================

--- Wraps a single node, with or without children. Returned by `Waffle:Flex()`, `AddChild`, `AddRow`, `AddColumn`,
--- `AttachComponent`, `FindByKey`, and `GetChildren`.
--- @class WaffleFlexComponent
--- @field package node WaffleFlexNode
_W.FlexComponent = {}
_W.FlexComponent.__index = _W.FlexComponent

--- Constructs components. Kept apart from `FlexComponent` so `New` is not
--- reachable as a method on a component.
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

-- Every setter below is a no-op unless the value changes, so redundant calls
-- (for example from an `OnUpdate`) stay cheap. `SetKey` is the exception.
-- Each setter is followed by its getter, which returns the raw value last
-- given, `nil` if never set. The default is documented on the setter only.
-- `frame` has a getter but no setter, and `frameFactory` has neither, since
-- neither changes after construction. Ordered as `WaffleFlexNode`'s fields are.

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

--- Returns this node's own `defaultFrameFactory`.
--- @return fun(parent: WaffleFrame): WaffleFrame?
function _W.FlexComponent:GetDefaultFrameFactory()
  return self.node.defaultFrameFactory
end

--- Sets this node's own main axis for its own children. `nil` resets to
--- the default (`"ROW"`). Case insensitive, any other value throws an error.
--- @param direction? WaffleFlexDirection
function _W.FlexComponent:SetDirection(direction)
  if direction ~= nil then _W.Utils:ParseEnum("direction", direction, DIRECTIONS) end
  if self.node.direction ~= direction then
    self.node.direction = direction
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns this node's own main axis for its own children.
--- @return WaffleFlexDirection?
function _W.FlexComponent:GetDirection()
  return self.node.direction
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

--- Returns this node's own width.
--- @return integer | "AUTO" | string | nil
function _W.FlexComponent:GetWidth()
  return self.node.width
end

--- Sets this node's own height. Same as `SetWidth()`, vertical instead.
--- @param height? integer | "AUTO" | string
function _W.FlexComponent:SetHeight(height)
  if self.node.height ~= height then
    self.node.height = height
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns this node's own height.
--- @return integer | "AUTO" | string | nil
function _W.FlexComponent:GetHeight()
  return self.node.height
end

--- Sets this node's own width and height together, equivalent to `SetWidth()`/`SetHeight()`.
--- Omitting either argument passes nil, resetting that dimension instead of leaving it unchanged.
--- @param width? integer | "AUTO" | string
--- @param height? integer | "AUTO" | string
function _W.FlexComponent:SetSize(width, height)
  self:SetWidth(width)
  self:SetHeight(height)
end

--- Returns this node's own width and height together.
--- @return integer | "AUTO" | string | nil width
--- @return integer | "AUTO" | string | nil height
function _W.FlexComponent:GetSize()
  return self.node.width, self.node.height
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

--- Returns this node's own share of its parent's leftover main-axis space.
--- @return number?
function _W.FlexComponent:GetGrow()
  return self.node.grow
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

--- Returns this node's own share of its parent's main-axis deficit.
--- @return number?
function _W.FlexComponent:GetShrink()
  return self.node.shrink
end

--- Sets how this node aligns its own children along the cross axis by
--- default. `nil` resets to the default (`"STRETCH"`). Case insensitive, any
--- other value throws an error.
--- @param align? WaffleFlexAlign
function _W.FlexComponent:SetAlign(align)
  if align ~= nil then _W.Utils:ParseEnum("align", align, ALIGNS) end
  if self.node.align ~= align then
    self.node.align = align
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns how this node aligns its own children along the cross axis by default.
--- @return WaffleFlexAlign?
function _W.FlexComponent:GetAlign()
  return self.node.align
end

--- Overrides the parent's `align` for this node. `nil` reverts to inheriting
--- it. Case insensitive, any other value throws an error.
--- @param alignSelf? WaffleFlexAlign
function _W.FlexComponent:SetAlignSelf(alignSelf)
  if alignSelf ~= nil then _W.Utils:ParseEnum("alignSelf", alignSelf, ALIGNS) end
  if self.node.alignSelf ~= alignSelf then
    self.node.alignSelf = alignSelf
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns this node's own override of the parent's `align`.
--- @return WaffleFlexAlign?
function _W.FlexComponent:GetAlignSelf()
  return self.node.alignSelf
end

--- Sets how this node distributes leftover main-axis space among its own
--- children. `nil` resets to the default (`"START"`). Case insensitive, any
--- other value throws an error.
--- @param justify? WaffleFlexJustify
function _W.FlexComponent:SetJustify(justify)
  if justify ~= nil then _W.Utils:ParseEnum("justify", justify, JUSTIFIES) end
  if self.node.justify ~= justify then
    self.node.justify = justify
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns how this node distributes leftover main-axis space among its own children.
--- @return WaffleFlexJustify?
function _W.FlexComponent:GetJustify()
  return self.node.justify
end

--- Sets whether this node's overflowing children wrap onto a new line.
--- `nil` resets to the default (`false`).
--- @param wrap? boolean
function _W.FlexComponent:SetWrap(wrap)
  if self.node.wrap ~= wrap then
    self.node.wrap = wrap
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns whether this node's overflowing children wrap onto a new line.
--- @return boolean?
function _W.FlexComponent:GetWrap()
  return self.node.wrap
end

--- Sets the space between this node's own children. `nil` resets to the
--- default (`0`).
--- @param gap? integer
function _W.FlexComponent:SetGap(gap)
  if self.node.gap ~= gap then
    self.node.gap = gap
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the space between this node's own children.
--- @return integer?
function _W.FlexComponent:GetGap()
  return self.node.gap
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

--- Returns the space between this node's own wrapped lines, instead of `GetGap()`.
--- @return integer?
function _W.FlexComponent:GetLineGap()
  return self.node.lineGap
end

--- Sets the space between this node's edge and its own children, on all
--- four sides. `nil` resets to the default (`0`). Overridden per side by
--- `SetPaddingTop()`/`SetPaddingRight()`/`SetPaddingBottom()`/`SetPaddingLeft()`.
--- @param padding? integer
function _W.FlexComponent:SetPadding(padding)
  if self.node.padding ~= padding then
    self.node.padding = padding
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the space between this node's edge and its own children, on
--- all four sides.
--- @return integer?
function _W.FlexComponent:GetPadding()
  return self.node.padding
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

--- Returns this node's own override of `GetPadding()` for its top side.
--- @return integer?
function _W.FlexComponent:GetPaddingTop()
  return self.node.paddingTop
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

--- Returns this node's own override of `GetPadding()` for its right side.
--- @return integer?
function _W.FlexComponent:GetPaddingRight()
  return self.node.paddingRight
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

--- Returns this node's own override of `GetPadding()` for its bottom side.
--- @return integer?
function _W.FlexComponent:GetPaddingBottom()
  return self.node.paddingBottom
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

--- Returns this node's own override of `GetPadding()` for its left side.
--- @return integer?
function _W.FlexComponent:GetPaddingLeft()
  return self.node.paddingLeft
end

--- Sets the space around this node itself, on all four sides. `nil`
--- resets to the default (`0`). Overridden per side by `SetMarginTop()`/
--- `SetMarginRight()`/`SetMarginBottom()`/`SetMarginLeft()`.
--- @param margin? integer
function _W.FlexComponent:SetMargin(margin)
  if self.node.margin ~= margin then
    self.node.margin = margin
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the space around this node itself, on all four sides.
--- @return integer?
function _W.FlexComponent:GetMargin()
  return self.node.margin
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

--- Returns this node's own override of `GetMargin()` for its top side.
--- @return integer?
function _W.FlexComponent:GetMarginTop()
  return self.node.marginTop
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

--- Returns this node's own override of `GetMargin()` for its right side.
--- @return integer?
function _W.FlexComponent:GetMarginRight()
  return self.node.marginRight
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

--- Returns this node's own override of `GetMargin()` for its bottom side.
--- @return integer?
function _W.FlexComponent:GetMarginBottom()
  return self.node.marginBottom
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

--- Returns this node's own override of `GetMargin()` for its left side.
--- @return integer?
function _W.FlexComponent:GetMarginLeft()
  return self.node.marginLeft
end

--- Sets a floor on this node's own `width`. `nil` removes it.
--- @param minWidth? number
function _W.FlexComponent:SetMinWidth(minWidth)
  if self.node.minWidth ~= minWidth then
    self.node.minWidth = minWidth
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the floor on this node's own `width`.
--- @return number?
function _W.FlexComponent:GetMinWidth()
  return self.node.minWidth
end

--- Sets a ceiling on this node's own `width`. `nil` removes it.
--- @param maxWidth? number
function _W.FlexComponent:SetMaxWidth(maxWidth)
  if self.node.maxWidth ~= maxWidth then
    self.node.maxWidth = maxWidth
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the ceiling on this node's own `width`.
--- @return number?
function _W.FlexComponent:GetMaxWidth()
  return self.node.maxWidth
end

--- Sets a floor on this node's own `height`. `nil` removes it.
--- @param minHeight? number
function _W.FlexComponent:SetMinHeight(minHeight)
  if self.node.minHeight ~= minHeight then
    self.node.minHeight = minHeight
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the floor on this node's own `height`.
--- @return number?
function _W.FlexComponent:GetMinHeight()
  return self.node.minHeight
end

--- Sets a ceiling on this node's own `height`. `nil` removes it.
--- @param maxHeight? number
function _W.FlexComponent:SetMaxHeight(maxHeight)
  if self.node.maxHeight ~= maxHeight then
    self.node.maxHeight = maxHeight
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the ceiling on this node's own `height`.
--- @return number?
function _W.FlexComponent:GetMaxHeight()
  return self.node.maxHeight
end

--- Sets this node's visibility. `"INVISIBLE"` hides its frame but keeps its
--- space in the layout. `"GONE"` excludes it from the layout flow
--- entirely; its siblings reflow to fill the space, and `Layout()` hides its
--- own frame and every already-resolved frame in its subtree. An ancestor's
--- own `visibility` affects this node's frame the same way, without changing
--- this node's own. `nil` resets to the default (`"VISIBLE"`). Case
--- insensitive, any other value throws an error.
--- @param visibility? WaffleFlexVisibility
function _W.FlexComponent:SetVisibility(visibility)
  _W.Utils:ParseVisibility(visibility)
  if self.node.visibility ~= visibility then
    self.node.visibility = visibility
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns this node's own `visibility` as given, never an ancestor's: a node
--- whose ancestor is `"INVISIBLE"` or `"GONE"` still returns `nil`/`"VISIBLE"`
--- here, even though its own frame is hidden too.
--- @return WaffleFlexVisibility?
function _W.FlexComponent:GetVisibility()
  return self.node.visibility
end

--- Returns `true` if this node's own `visibility` is `"VISIBLE"` or unset, in
--- any case. Ignores an ancestor's `visibility` and whether its frame is
--- actually shown.
--- @return boolean
function _W.FlexComponent:IsVisible()
  return _W.Utils:ParseVisibility(self.node.visibility) == "VISIBLE"
end

--- Sets this node's own `key`, for lookup via `FindByKey(key)`. `nil`
--- removes it. Unlike every other setter, never marks the tree dirty:
--- `FindByKey` always searches live, there's nothing to recompute.
--- @param key? string
function _W.FlexComponent:SetKey(key)
  self.node.key = key
end

--- Returns this node's own `key`.
--- @return string?
function _W.FlexComponent:GetKey()
  return self.node.key
end

--- Sets this node's visual position among siblings, independent of
--- declaration order. `nil` resets to the default (`0`).
--- @param order? integer
function _W.FlexComponent:SetOrder(order)
  if self.node.order ~= order then
    self.node.order = order
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns this node's own visual position among siblings.
--- @return integer?
function _W.FlexComponent:GetOrder()
  return self.node.order
end

--- Sets the callback fired once this node's own `Layout()` pass is
--- resolved and clean. `nil` removes it.
--- @param onLayout? fun(frame: WaffleFrame, width: integer, height: integer)
function _W.FlexComponent:SetOnLayout(onLayout)
  if self.node.onLayout ~= onLayout then
    self.node.onLayout = onLayout
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the callback fired once this node's own `Layout()` pass is
--- resolved and clean.
--- @return fun(frame: WaffleFrame, width: integer, height: integer)?
function _W.FlexComponent:GetOnLayout()
  return self.node.onLayout
end

--- Sets the callback that sizes this node's content when it leaves a size
--- `"AUTO"`. `nil` removes it.
--- @param onMeasure? fun(frame: WaffleFrame, width?: number, height?: number): number, number
function _W.FlexComponent:SetOnMeasure(onMeasure)
  if self.node.onMeasure ~= onMeasure then
    self.node.onMeasure = onMeasure
    _W.DirtyRoots:Mark(self.node)
  end
end

--- Returns the callback that sizes this node's content when it leaves a size
--- `"AUTO"`.
--- @return (fun(frame: WaffleFrame, width?: number, height?: number): number, number)?
function _W.FlexComponent:GetOnMeasure()
  return self.node.onMeasure
end

--- Looks up a component anywhere in the tree by its `key`, erroring if
--- none is found. A duplicate key isn't validated against, the first
--- match wins.
--- @param key string
--- @return WaffleFlexComponent
function _W.FlexComponent:FindByKey(key)
  local root = _W.Ownership:FindRoot(self.node)
  local found = _W.FlexComponentFactory:FindNodeByKey(root, key)
  assert(found, "Waffle: no component registered under key '" .. key .. "'")
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

--- Calls `callback` once with this node's frame: immediately if the frame
--- already exists, otherwise right after Waffle creates it, before it is
--- parented, sized, or shown. Callbacks run in registration order. When one
--- runs during a `Layout()` pass, touch only the frame; mutating the tree
--- is unsupported.
--- @param callback fun(frame: WaffleFrame)
function _W.FlexComponent:WhenFrameReady(callback)
  local node = self.node
  if node.frame then
    callback(node.frame)
    return
  end

  _W.FrameReadyQueue:Add(node, callback)
end

--- Returns `true` if this node's tree has changed since its last `Layout()` call.
--- @return boolean
function _W.FlexComponent:IsDirty()
  return _W.DirtyRoots:IsDirty(_W.Ownership:FindRoot(self.node))
end

--- Marks this node's tree dirty, so the next `Layout()` runs even though no
--- field changed. For a node whose content changed, such as text sized by
--- `onMeasure`.
function _W.FlexComponent:MarkDirty()
  _W.DirtyRoots:Mark(self.node)
end

--- Runs the layout for the tree containing this node, starting from its
--- actual current root. No-ops unless something changed since the last
--- call, cheap to call from e.g. an `OnUpdate` handler every frame.
function _W.FlexComponent:Layout()
  local root = _W.Ownership:FindRoot(self.node)
  if _W.DirtyRoots:IsDirty(root) then
    _W.LayoutCache.currentPass = _W.LayoutCache.currentPass + 1
    local onLayoutQueue = _W.Scratch:Get()

    local rootVisibility = _W.Utils:ParseVisibility(root.visibility)
    if rootVisibility == "GONE" then
      _W.Utils:HideResolvedFrames(root)
    else
      local frame = _W.Utils:ResolveFrame(root)
      if rootVisibility == "INVISIBLE" then
        frame:Hide()
      else
        frame:Show()
      end

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

-- `AddChild`, `AddRow`, `AddColumn`, and `AttachComponent` create
-- `children` on the node if it has none.

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

--- Detaches from the tree entirely, unlike `"GONE"`. Doesn't touch
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
