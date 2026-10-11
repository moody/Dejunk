# Changelog

## [3.4.0] - Unreleased

### Added

- Added a `Keybindings` page to the main window. Click a button, then press a key, a mouse button, or the mouse wheel to bind it, or right-click a button to unbind it. A key set here takes priority over the game's own binding for it, and a note names the game binding it covers. Keybindings cannot be changed in combat.

### Fixed

- Fixed the game freezing on WoW Forever with gamepad support enabled after opening and closing the game's Keybindings page with Dejunk enabled.

### Removed

- Removed Dejunk's section from the game's Keybindings page. Keys bound there are lost, so set them again on the new `Keybindings` page.
- Removed the keyboard button from the main window's title bar, which opened the game's Keybindings page.
