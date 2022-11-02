# Changelog

## [Unreleased]

### Added

- Additional tooltips and `OnClick` handling for List Frame and Junk Frame item buttons ([#144](https://github.com/moody/Dejunk/issues/144))

### Changed

- Removed sound effects

## [1.3.3] - 2022-10-30

### Fixed

- Protected function errors in Retail ([#153](https://github.com/moody/Dejunk/issues/153))

## [1.3.2] - 2022-10-29

### Changed

- Unified the functionality of the merchant and minimap buttons
- Updated option `Auto Junk Frame` to also apply when opening/closing bags
- Updated code for compatibility with Dragonflight beta

### Fixed

- Cloaks are no longer considered unsuitable equipment for non-cloth characters in Retail ([#143](https://github.com/moody/Dejunk/issues/143))
- The `/dejunk keybinds` command and UI button now navigate to the new Dragonflight keybinding UI ([#145](https://github.com/moody/Dejunk/issues/145))

## [1.3.1] - 2022-10-26

### Changed

- Updated code for Dragonflight pre-patch
- Modified the size and location of the Merchant Button (now appears at the bottom right corner)

### Fixed

- Static popup handling for tradeable items in Wrath

## [1.3.0] - 2022-10-09

### Added

- Profit message after items are sold and confirmed
- Transport frame, which allows importing and exporting item IDs for the Inclusions and Exclusions lists
  - The frame can be opened via command or by clicking a list's title within the options frame
- Command: `/dejunk transport {inclusions|exclusions}`

### Changed

- Added an `onUpdateTooltip` option to `Widgets:Frame()` to allow for dynamic tooltips
- Modified the tooltip for the `Include Below Average Equipment` option to include the player's equipped item level

## [1.2.0] - 2022-10-04

### Added

- Option: `Auto Junk Frame`

### Changed

- Updated the `/dejunk loot` command to close the loot frame when called

## [1.1.0] - 2022-10-02

### Added

- Option: `Include Below Average Equipment`
- Option: `Include Unsuitable Equipment`
- Command: `/dejunk keybinds`

### Changed

- SavedVariables now populate/depopulate default values on login/logout
- Made some minor UI modifications
- Junk frame now displays individual item stack prices
- Updated the options frame to have "Keybinds" button

### Fixed

- Fixed bug with initial slider values in the ItemsFrame

## [1.0.2] - 2022-09-26

### Fixed

- Fixed bug with the `/dejunk loot` command

## [1.0.1] - 2022-09-26

### Added

- Vanilla .toc file

### Changed

- Windows are now added to UISpecialFrames
- Option buttons now dynamically resize
- Certain UI interactions now play sounds

## [1.0.0] - 2022-09-25

### Changed

- Rebuilt addon from the ground up
