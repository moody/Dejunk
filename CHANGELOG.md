# Changelog

## [3.4.0] - 2026-10-11

### Added

- Added a `Keybindings` page to the main window. Click a button, then press a key, a mouse button, or the mouse wheel to bind it, or right-click a button to unbind it. A key set here takes priority over the game's own binding for it, and a note names the game binding it covers. Keybindings cannot be changed in combat.

### Changed

- `DejunkApi:IsJunk()` now reuses its results until the bags, the options, or the equipment sets change, and refreshes the equipment sets at most once per frame. This is an attempt to reduce the CPU spike when opening the bank or Warband bank with Baganator enabled ([#280](https://github.com/moody/Dejunk/issues/280)).

### Fixed

- Fixed the game freezing on WoW Forever with gamepad support enabled after opening and closing the game's Keybindings page with Dejunk enabled.

### Removed

- Removed Dejunk's section from the game's Keybindings page. Keys bound there are lost, so set them again on the new `Keybindings` page.
- Removed the keyboard button from the main window's title bar, which opened the game's Keybindings page.
