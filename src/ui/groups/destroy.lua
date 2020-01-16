local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local Destroy = Addon.UI.Groups.Destroy
local Exclusions = Addon.Lists.Exclusions
local Inclusions = Addon.Lists.Inclusions
local L = Addon.Libs.L
local Utils = Addon.UI.Utils

-- Upvalues
local GetCoinTextureString = _G.GetCoinTextureString

function Destroy:Create(parent)
  Utils:Heading(parent, L.DESTROY_TEXT)
  self:AddGeneral(parent)
  self:AddByQuality(parent)
  self:AddByType(parent)
  self:AddIgnore(parent)
end

function Destroy:AddGeneral(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.GENERAL_TEXT,
    fullWidth = true
  })

  -- Auto Destroy
  Utils:CheckBox({
    parent = parent,
    label = L.AUTO_DESTROY_TEXT,
    tooltip = L.AUTO_DESTROY_TOOLTIP,
    get = function() return DB.Profile.AutoDestroy end,
    set = function(value) DB.Profile.AutoDestroy = value end
  })

  -- Below Price
  Utils:CheckBoxSlider({
    parent = parent,
    checkBox = {
      label = L.DESTROY_BELOW_PRICE_TEXT,
      tooltip = L.DESTROY_BELOW_PRICE_TOOLTIP,
      get = function() return DB.Profile.DestroyBelowPrice.Enabled end,
      set = function(value) DB.Profile.DestroyBelowPrice.Enabled = value end
    },
    slider = {
      label = GetCoinTextureString(DB.Profile.DestroyBelowPrice.Value),
      value = DB.Profile.DestroyBelowPrice.Value,
      min = Consts.DESTROY_BELOW_PRICE_MIN,
      max = Consts.DESTROY_BELOW_PRICE_MAX,
      step = Consts.DESTROY_BELOW_PRICE_STEP,
      onValueChanged = function(self, event, value)
        DB.Profile.DestroyBelowPrice.Value = value
        self:SetLabel(GetCoinTextureString(DB.Profile.DestroyBelowPrice.Value))
      end
    }
  })
end

function Destroy:AddByQuality(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.BY_QUALITY_TEXT,
    fullWidth = true
  })

  -- Poor
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.POOR_TEXT, DCL.Wow.Poor),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.DestroyPoor end,
    set = function(value) DB.Profile.DestroyPoor = value end
  })

  -- Common
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.COMMON_TEXT, DCL.Wow.Common),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.DestroyCommon end,
    set = function(value) DB.Profile.DestroyCommon = value end
  })

  -- Uncommon
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.UNCOMMON_TEXT, DCL.Wow.Uncommon),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.DestroyUncommon end,
    set = function(value) DB.Profile.DestroyUncommon = value end
  })

  -- Rare
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.RARE_TEXT, DCL.Wow.Rare),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.DestroyRare end,
    set = function(value) DB.Profile.DestroyRare = value end
  })

  -- Epic
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.EPIC_TEXT, DCL.Wow.Epic),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.DestroyEpic end,
    set = function(value) DB.Profile.DestroyEpic = value end
  })
end

function Destroy:AddByType(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.BY_TYPE_TEXT,
    fullWidth = true
  })

  -- Inclusions
  Utils:CheckBox({
    parent = parent,
    label = Inclusions.localeColored,
    tooltip = L.DESTROY_LIST_TOOLTIP:format(Inclusions.localeColored),
    get = function() return DB.Profile.DestroyInclusions end,
    set = function(value) DB.Profile.DestroyInclusions = value end
  })

  if Addon.IS_RETAIL then
    -- Pets already collected
    Utils:CheckBox({
      parent = parent,
      label = L.DESTROY_PETS_ALREADY_COLLECTED_TEXT,
      tooltip = L.DESTROY_PETS_ALREADY_COLLECTED_TOOLTIP,
      get = function() return DB.Profile.DestroyPetsAlreadyCollected end,
      set = function(value) DB.Profile.DestroyPetsAlreadyCollected = value end
    })

    -- Toys already collected
    Utils:CheckBox({
      parent = parent,
      label = L.DESTROY_TOYS_ALREADY_COLLECTED_TEXT,
      tooltip = L.DESTROY_TOYS_ALREADY_COLLECTED_TOOLTIP,
      get = function() return DB.Profile.DestroyToysAlreadyCollected end,
      set = function(value) DB.Profile.DestroyToysAlreadyCollected = value end
    })
  end

  -- Excess Soul Shards
  if Addon.IS_CLASSIC then
    Utils:CheckBoxSlider({
      parent = parent,
      checkBox = {
        label = L.DESTROY_EXCESS_SOUL_SHARDS_TEXT,
        tooltip = L.DESTROY_EXCESS_SOUL_SHARDS_TOOLTIP,
        get = function() return DB.Profile.DestroyExcessSoulShards.Enabled end,
        set = function(value)
          DB.Profile.DestroyExcessSoulShards.Enabled = value
        end
      },
      slider = {
        label = L.DESTROY_EXCESS_SOUL_SHARDS_SLIDER_LABEL,
        value = DB.Profile.DestroyExcessSoulShards.Value,
        min = Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN,
        max = Consts.DESTROY_EXCESS_SOUL_SHARDS_MAX,
        step = Consts.DESTROY_EXCESS_SOUL_SHARDS_STEP,
        onValueChanged = function(self, event, value)
          DB.Profile.DestroyExcessSoulShards.Value = value
        end
      }
    })
  end
end

function Destroy:AddIgnore(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.IGNORE_TEXT,
    fullWidth = true
  })

  -- Exclusions
  Utils:CheckBox({
    parent = parent,
    label = Exclusions.localeColored,
    tooltip = L.DESTROY_IGNORE_LIST_TOOLTIP:format(Exclusions.localeColored),
    get = function() return DB.Profile.DestroyIgnoreExclusions end,
    set = function(value) DB.Profile.DestroyIgnoreExclusions = value end
  })

  -- Readable
  Utils:CheckBox({
    parent = parent,
    label = L.IGNORE_READABLE_TEXT,
    tooltip = L.IGNORE_READABLE_TOOLTIP,
    get = function() return DB.Profile.DestroyIgnoreReadable end,
    set = function(value) DB.Profile.DestroyIgnoreReadable = value end
  })
end
