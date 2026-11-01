# Changelog

## [3.5.0] - Unreleased

### Added

- Added a `Profiles` page to the main window for creating, activating, renaming, resetting, and deleting profiles.

### Changed

- `/dejunk profiles` and the profiles button in the game's Dejunk settings now open the `Profiles` page.
- The Junk Items frame, the Lootable Items frame, and the lists now show items as cards with a strip in the item's quality color.
- An item that is locked, such as one on the cursor or in a trade, now stays in the Junk Items frame, dimmed, and keeps its bag icon and tooltip reason, instead of dropping out until it unlocks.
- Each list now has a single keybinding that adds or removes the item shown in the game tooltip, replacing its separate add and remove keybindings. Your saved key is kept: the `Add to` key if you set one, otherwise the `Remove from` key.

### Fixed

- Fixed Auto Sell and the sell buttons stopping after a small first batch when the bags had not finished loading. Selling now waits for the bags to settle and continues until no sellable junk is left.
- Fixed an item you just bought and can still refund showing as junk until the next bag update. It is now protected as soon as the game reports its refund time.

### Removed

- Removed the Profiles Frame and the gear button in the main window's footer that opened it.
