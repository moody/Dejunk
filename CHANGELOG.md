# Changelog

## [Unreleased]

### Added

- Added `Auto Lootables Frame`, a global option that shows the Lootable Items frame automatically when you have items to loot, and closes it once you don't.
- Manually opening the Lootable Items frame with nothing to loot now prints a message instead of showing an empty frame.

### Changed

- `Bag Item Icons` now overlays a small icon in the item's top-left corner instead of covering the whole slot, with a lighter background behind it.
- `Auto Junk Frame` now reacts to whether you actually have junk while at a merchant, instead of just opening when the merchant window opens and closing when it closes. It opens as soon as you have junk, even if that's not until partway through the visit (a list or setting change can turn bag items into junk, buying an item back can too), and closes itself once you no longer have any. Closing it yourself keeps it closed for the rest of that visit; leaving the merchant always closes it.
