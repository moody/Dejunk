# Dejunk

Dejunk is an addon for World of Warcraft that helps determine which items are considered junk based on options and lists, then allows selling them in bulk or destroying them one at a time.

![Dejunk](/.github/images/Dejunk.png?raw=true)

## Features

- Sell junk automatically or on demand
- Destroy junk one at a time, with optional confirmation
- Separate settings and lists per profile, shareable across characters
- Tooltips explain why an item is considered junk
- Auto-repair equipment at merchants
- Overlay icons on junk in your bags
- Open lootable items one at a time from a dedicated frame
- Use keybindings or chat commands for most actions

### Options

These options, found under `Options (Profile)`, determine what's considered junk. Several support per-quality checkboxes, letting them apply only to specific quality tiers.

- **Include By Quality** — Include items by quality tier (poor quality included by default)
- **Exclude Above Item Level** — Exclude equipment above a set item level, even if it's on an Inclusions list
- **Include Below Item Level** — Include equipment below a set item level
- **Include Unsuitable Equipment** — Include equipment with an armor or weapon type unsuitable for your class
- **Exclude Equipment Sets** — Exclude equipment saved to an equipment set _(Not available on Classic Era or TBC Classic)_
- **Exclude Unbound Equipment** — Exclude equipment that is not yet bound
- **Exclude Warband Equipment** — Exclude equipment eligible for the warband bank _(Retail only)_
- **Include Artifact Relics** — Include artifact relic gems _(Retail only)_

### Lists

Inclusions and Exclusions lists are available at both the global and per-profile level. Per-profile lists take priority over global ones.

- **`Inclusions (Global)`** — Always considered junk across all characters, unless overridden by a per-profile exclusion or `Exclude Above Item Level`
- **`Exclusions (Global)`** — Never considered junk across all characters, unless overridden by a per-profile inclusion
- **`Inclusions (Profile)`** — Always considered junk for the active profile only, regardless of any other setting except `Exclude Above Item Level`
- **`Exclusions (Profile)`** — Never considered junk for the active profile only, regardless of any other setting

Items can be added to lists by dropping them directly into the list frame or the Junk Items frame.

### Import/Export

Each list has its own Import/Export frame, opened from a button on the list frame itself. It shows the list's item IDs as plain text, ready to copy out. Paste in a new set of IDs and click `Import` to add them to the list, or click `Export` to refill the box with the list's current IDs.

![Import/Export](/.github/images/TransportFrame.png?raw=true)

### Junk Items

The Junk Items frame, opened via `/dejunk junk` or its keybind, lists items currently considered junk along with their total sell value.

- Left-click an item to sell it
- Right-click an item to add it to an Exclusions list
- Drop an item into the frame to add it to an Inclusions list
- `Start Selling` and `Destroy Next Item` act on every item currently listed

![Junk Items](/.github/images/JunkFrame.png?raw=true)

### Profiles

Each character is assigned a profile, which holds its own `Inclusions (Profile)` and `Exclusions (Profile)` lists along with its own copy of the auto-sell, auto-repair, and junk-detection options. Multiple characters can share the same profile.

Every character starts on the `Default` profile. Adding an item to a profile list while on `Default` creates a new profile for that character and switches to it automatically.

Profiles can also be created, switched, renamed, and deleted directly from the Profiles Frame, opened via `/dejunk profiles`, its keybind, or the gear icon in the main window's footer. The footer also shows the name of the active profile. The `Default` profile cannot be renamed or deleted, and deleting the active profile switches back to `Default`.

![Profiles Frame](/.github/images/ProfilesFrame.png?raw=true)

### Lootable Items

Lootable bag items, such as those that need to be right-clicked to open, are listed in the Lootable Items Frame, opened via `/dejunk loot` or its keybind. Click an item to attempt to open it; a loot window may prompt for confirmation depending on your own auto-loot setting. Each item also has a button to ignore all instances of that item for the remainder of the session.

![Lootable Items Frame](/.github/images/LootablesFrame.png?raw=true)

## Chat Commands

```bash
# Toggle the options frame.
/dejunk

# Start selling items.
/dejunk sell

# Destroy next item.
/dejunk destroy

# Toggle the junk frame.
/dejunk junk

# Toggle the lootable items frame.
/dejunk loot

# Toggle the profiles frame.
/dejunk profiles

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
- [Waffle](https://github.com/moody/Waffle)
- [Wux](https://github.com/moody/Wux)

## License

[MIT](LICENSE)
