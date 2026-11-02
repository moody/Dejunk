# Changelog

## [3.5.0] - Unreleased

### Added

- Added a `Profiles` page to the main window for creating, activating, renaming, resetting, and deleting profiles.

### Changed

- `/dejunk profiles` and the profiles button in the game's Dejunk settings now open the `Profiles` page.
- The Junk Items frame, the Lootable Items frame, and the lists now show items as cards with a strip in the item's quality color.
- An item that is locked, such as one on the cursor or in a trade, now stays in the Junk Items frame, dimmed, and keeps its bag icon and tooltip reason, instead of dropping out until it unlocks.
- Each list now has a single keybinding that adds or removes the item shown in the game tooltip, replacing its separate add and remove keybindings. Your saved key is kept: the `Add to` key if you set one, otherwise the `Remove from` key.
- The Junk Items frame title now shows how many junk items can be sold and destroyed, like the merchant button, in place of the total.
- An item you can still refund now shows as junk like any other. Selling skips it, since the game does not let an addon sell it; its tooltip says why, and clicking it in the Junk Items frame prints the reason. Destroying it works.

### Fixed

- Fixed Auto Sell and the sell buttons stopping after a small first batch when the bags had not finished loading. Selling now waits for the bags to settle and continues until no sellable junk is left.

### Removed

- Removed the Profiles Frame and the gear button in the main window's footer that opened it.
