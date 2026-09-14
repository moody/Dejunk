# Changelog

## [Unreleased]

### Added

- Profiles. Each character has a profile holding its `Inclusions (Profile)` list, `Exclusions (Profile)` list, and its own copy of the character-specific options. Every character starts on the `Default` profile, whose lists cannot be edited directly; the first time you add an item to a profile list, Dejunk creates a profile for that character and switches to it. The active profile's name is printed to chat whenever it changes.
- A `Profiles` frame for managing profiles directly, opened via the gear icon in the main window's footer (which also shows the active profile's name). Profiles can be created, switched, renamed, and deleted from this frame. The `Default` profile cannot be renamed or deleted, and deleting the active profile switches back to `Default`.
- The `/dejunk profiles` chat command, for opening the `Profiles` frame directly.
- `Safe Destroy`, a `Global` option that shows a confirmation popup before destroying an item.

### Changed

- The `Inclusions (Character)` and `Exclusions (Character)` lists are now named `Inclusions (Profile)` and `Exclusions (Profile)`. Existing lists carry over automatically.
- The options window is split into `Profile` and `Global` sections, each with a heading.
- Removed the `Character Specific Settings` option. The options it controlled are now always part of the active profile:
  1. `Auto Repair`
  2. `Auto Sell`
  3. `Exclude Equipment Sets`
  4. `Exclude Unbound Equipment`
  5. `Exclude Warband Equipment`
  6. `Include Artifact Relics`
  7. `Include Below Item Level`
  8. `Include By Quality`
  9. `Include Unsuitable Equipment`

  If you had `Character Specific Settings` disabled and relied on a shared global value for any of these, set that option again on each character.
- `Safe Mode` is renamed to `Safe Sell`.
- `Auto Junk Frame` and `Safe Sell` are now `Global` options instead of `Profile` options, so they apply to every character rather than only the active profile.
- On the `Minimap Icon`, Left-Click now toggles the options frame (previously the junk frame) and Right-Click now toggles the junk frame (previously the options frame). Shift+Left-Click no longer starts selling.
- On the `Merchant Button`, Right-Click now toggles the junk frame (previously the options frame). Shift+Left-Click no longer toggles the junk frame, since Right-Click already does.
- `/dejunk loot` and its keybind now open a `Lootable Items` frame instead of immediately attempting to open every lootable item. Click an item in the frame to attempt to open it; a loot window may prompt for confirmation depending on your own auto-loot setting.

### Removed

- The `/dejunk keybinds` and `/dejunk transport` chat commands. Key bindings are still reachable from the keybinds button in the main window's title bar, and each list frame still has its own button for opening the transport frame.

### Fixed

- Fixed excessive memory usage with refundable items in specific conditions.
