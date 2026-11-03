# Changelog

## [3.5.0] - Unreleased

### Added

- Added a `Profiles` page to the main window for creating, activating, renaming, resetting, and deleting profiles.
- Added sell, destroy, and exclude buttons to each item in the Junk Items frame. Exclude adds the item to an Exclusions list, or the global one while holding Shift. Sell and destroy work on any listed item, even one that is junk only for the other action, and are dimmed while the item cannot be sold or destroyed. Their tooltips show whether the item is being sold or destroyed, and why.

### Changed

- `/dejunk profiles` and the profiles button in the game's Dejunk settings now open the `Profiles` page.
- The Junk Items frame, the Lootable Items frame, and the lists now show items as cards with a strip in the item's quality color.
- An item that is locked, such as one on the cursor or in a trade, now stays in the Junk Items frame, dimmed, and keeps its bag icon and tooltip reason, instead of dropping out until it unlocks.
- Each list now has a single keybinding that adds or removes the item shown in the game tooltip, replacing its separate add and remove keybindings. Your saved key is kept: the `Add to` key if you set one, otherwise the `Remove from` key.
- Clicking an item in the Junk Items frame no longer sells, excludes, or destroys it. Use the buttons on the item instead.
- The Junk Items frame title now shows how many junk items can be sold and destroyed, like the merchant button, in place of the total.
- An item you can still refund now shows as junk like any other. Selling skips it, since the game does not let an addon sell it; its tooltip says why. Destroying it works.

### Fixed

- Fixed Auto Sell and the sell buttons stopping after a small first batch when the bags had not finished loading. Selling now waits for the bags to settle and continues until no sellable junk is left.

### Removed

- Removed the Profiles Frame and the gear button in the main window's footer that opened it.
