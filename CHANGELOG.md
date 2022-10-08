# Changelog

## [Unreleased]

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
