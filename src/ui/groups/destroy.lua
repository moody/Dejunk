local AddonName, Addon = ...
local L = Addon.Libs.L
local AceGUI = Addon.Libs.AceGUI
local Utils = Addon.UI.Utils
local Destroy = Addon.UI.Groups.Destroy
local DCL = Addon.Libs.DCL
local Consts = Addon.Consts
local DB = Addon.DB
local Tools = Addon.Tools

-- Upvalues
local GetCoinTextureString = _G.GetCoinTextureString

function Destroy:Create(parent)
  Utils:Heading(parent, L.DESTROY_TEXT)
  self:AddGeneral(parent)
  self:AddDestroy(parent)
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

  do -- Below price
    local group = Utils:SimpleGroup({
      parent = parent,
      fullWidth = true
    })

    local slider = AceGUI:Create("Slider")
    slider:SetSliderValues(
      Consts.DESTROY_BELOW_PRICE_MIN,
      Consts.DESTROY_BELOW_PRICE_MAX,
      Consts.DESTROY_BELOW_PRICE_STEP
    )
    slider:SetLabel(GetCoinTextureString(DB.Profile.DestroyBelowPrice.Value))
    slider:SetValue(DB.Profile.DestroyBelowPrice.Value)
    slider:SetDisabled(not DB.Profile.DestroyBelowPrice.Enabled)
    slider:SetCallback("OnValueChanged", function(widget, event, value)
      DB.Profile.DestroyBelowPrice.Value = value
      slider:SetLabel(GetCoinTextureString(DB.Profile.DestroyBelowPrice.Value))
    end)

    Utils:CheckBox({
      parent = group,
      label = L.DESTROY_BELOW_PRICE_TEXT,
      tooltip = L.DESTROY_BELOW_PRICE_TOOLTIP,
      get = function() return DB.Profile.DestroyBelowPrice.Enabled end,
      set = function(value)
        DB.Profile.DestroyBelowPrice.Enabled = value
        slider:SetDisabled(not value)
      end
    })

    group:AddChild(slider)
  end
end

function Destroy:AddDestroy(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.DESTROY_TEXT,
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

  -- Inclusions
  Utils:CheckBox({
    parent = parent,
    label = L.INCLUSIONS_TEXT,
    tooltip = L.DESTROY_LIST_TOOLTIP:format(Tools:GetInclusionsString()),
    get = function() return DB.Profile.DestroyInclusions end,
    set = function(value) DB.Profile.DestroyInclusions = value end
  })

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

function Destroy:AddIgnore(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.IGNORE_TEXT,
    fullWidth = true
  })

  -- Exclusions
  Utils:CheckBox({
    parent = parent,
    label = L.EXCLUSIONS_TEXT,
    tooltip = L.DESTROY_IGNORE_LIST_TOOLTIP:format(Tools:GetExclusionsString()),
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
