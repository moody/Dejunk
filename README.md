# Dejunk

Dejunk is an addon for automating some tedious aspects of selling and destroying items. It supports Retail, Classic Era, TBC Classic, Cataclysm Classic, and Mists Classic.

By default, all poor quality items are considered junk. Higher quality items can be caught automatically using filters, or manually added to an `Inclusions` list. Items on an `Exclusions` list will never be considered junk.

Once set up, Dejunk can handle the process of selling or destroying junk items with the press of a button.

![Dejunk](/.images/Dejunk.png?raw=true)

## Features

- Sell junk items at a merchant automatically or on demand
- Destroy junk items one at a time
- Auto-repair and auto-sell when opening a merchant
- Open all lootable bag items with a single command
- Overlay icons on junk items in your bags
- Add Dejunk information to item tooltips, including the reason an item is considered junk
- Set up keybindings or use chat commands for most operations

### Filters

Filters determine what items are considered junk. Several filters support per-quality checkboxes, allowing them to apply only to specific quality tiers.

**Include** (marks matched items as junk)

- **Include By Quality** — Include items by quality tier
- **Include Below Item Level** — Include equipment below a set item level
- **Include Unsuitable Equipment** — Include equipment with an armor or weapon type unsuitable for your class
- **Include Artifact Relics** — Include artifact relic gems _(Retail only)_

**Exclude** (prevents matched items from being considered junk)

- **Exclude Equipment Sets** — Exclude equipment saved to an equipment set
- **Exclude Unbound Equipment** — Exclude equipment that is not yet bound
- **Exclude Warband Equipment** — Exclude equipment eligible for the warband bank _(Retail only)_

### Lists

Inclusions and Exclusions lists are available at both the global and per-character level. Per-character lists take priority over global ones.

| List                 | Behaviour                                                                         |
| -------------------- | --------------------------------------------------------------------------------- |
| Global Inclusions    | Always junk across all characters, unless overridden by a per-character exclusion |
| Global Exclusions    | Never junk across all characters, unless overridden by a per-character inclusion  |
| Character Inclusions | Always junk for this character only, regardless of any other setting              |
| Character Exclusions | Never junk for this character only, regardless of any other setting               |

Items can be added to lists by dragging them directly into the list frame or the Junk Frame. The Transport Frame can be used to import or export item IDs as plain text, making it easy to share or back up lists.

![Junk Frame](/.images/JunkFrame.png?raw=true)
![Transport Frame](/.images/TransportFrame.png?raw=true)

## Chat Commands

```bash
# Toggle the options frame.
/dejunk

# Start selling items.
/dejunk sell

# Destroy next item.
/dejunk destroy

# Open lootable items.
/dejunk loot

# Toggle the junk frame.
/dejunk junk

# Open the key binding frame.
/dejunk keybinds

# Toggle the transport frame.
/dejunk transport inclusions global
/dejunk transport inclusions character
/dejunk transport exclusions global
/dejunk transport exclusions character

# Display a list of commands.
/dejunk help
```

## Developer API

Dejunk exposes a public API for other addons to integrate with.

```lua
-- Subscribe to bag cache and state change events.
local removeListener = DejunkApi:AddListener(function(event)
  if event == DejunkApi.Events.BagsUpdated then ... end
  if event == DejunkApi.Events.StateUpdated then ... end
end)

-- Check whether an item is considered junk.
local isJunk = DejunkApi:IsJunk(bagId, slotId)
```

## Credit

### Art

- [Cash icon](https://game-icons.net/1x1/lorc/cash.html) by [Lorc](http://lorcblog.blogspot.com/) under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/).
- [FontAwesome](https://fontawesome.com/) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

### Libraries

- [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler)
- [LibDataBroker-1.1](https://www.wowace.com/projects/libdatabroker-1-1)
- [LibDBIcon-1.0](https://www.wowace.com/projects/libdbicon-1-0)
- [LibStub](https://www.wowace.com/projects/libstub)
