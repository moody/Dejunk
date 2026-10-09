--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")
local Matchers = require("test/matchers")

-- ============================================================================
-- Setup
-- ============================================================================

local Context = Harness:NewContext()
Context:Load("src/utils/coins.lua")
local Coins = Context:GetModule("Coins")

-- ============================================================================
-- Tests - Coins:Combine()
-- ============================================================================

-- Test: returns 0 for no coins.
assert(Coins:Combine(0, 0, 0) == 0)

-- Test: carries silver and copper above 99 into the larger units.
assert(Coins:Combine(0, 150, 250) == 15250)

-- Test: combines gold, silver, and copper into total copper.
assert(Coins:Combine(12, 34, 56) == 123456)

-- ============================================================================
-- Tests - Coins:Split()
-- ============================================================================

-- Test: splits total copper into gold, silver, and copper.
assert(Matchers:IsDeepEqual({ Coins:Split(123456) }, { 12, 34, 56 }))

-- Test: returns zeros for 0 copper.
assert(Matchers:IsDeepEqual({ Coins:Split(0) }, { 0, 0, 0 }))

-- Test: returns only copper when there is no gold or silver.
assert(Matchers:IsDeepEqual({ Coins:Split(56) }, { 0, 0, 56 }))

-- Test: returns only silver when there is no gold or copper.
assert(Matchers:IsDeepEqual({ Coins:Split(3400) }, { 0, 34, 0 }))

-- Test: returns whole gold with no silver or copper.
assert(Matchers:IsDeepEqual({ Coins:Split(50000) }, { 5, 0, 0 }))

-- Test: carries 100 copper into 1 silver.
assert(Matchers:IsDeepEqual({ Coins:Split(99) }, { 0, 0, 99 }))
assert(Matchers:IsDeepEqual({ Coins:Split(100) }, { 0, 1, 0 }))

-- Test: carries 100 silver into 1 gold.
assert(Matchers:IsDeepEqual({ Coins:Split(9999) }, { 0, 99, 99 }))
assert(Matchers:IsDeepEqual({ Coins:Split(10000) }, { 1, 0, 0 }))
