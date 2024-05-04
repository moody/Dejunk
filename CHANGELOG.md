# Changelog

## [Unreleased]

### Added

- Added a `Search Lists` button to the options frame which enables searching lists by item name ([#198](https://github.com/moody/Dejunk/issues/198))

### Changed

- Modified some icons

## [1.8.1] - 2024-05-03

### Changed

- Refactored UI to display all lists together
- Updated dependencies

### Removed

- Switch view functionality for list frames

## [1.8.0] - 2024-04-30

### Changed

- Allow any delimiter when importing ([#197](https://github.com/moody/Dejunk/issues/197))
- Refactored SavedVariables code
- Updated for Cataclysm Classic

## [1.7.3] - 2024-02-09

- Bump TOC versions

## [1.7.2] - 2024-01-08

### Fixed

- Issue causing items to be permanently removed from lists if not parsed within 5 seconds of logging in ([#193](https://github.com/moody/Dejunk/issues/193))

## [1.7.1] - 2023-12-28

### Changed

- Refactored code to no longer use `C_Timer` functions

### Fixed

- Performance issues related to the new `Exclude Equipment Sets` option ([#190](https://github.com/moody/Dejunk/issues/190))

## [1.7.0] - 2023-12-25

### Added

- Option: `Exclude Equipment Sets` ([#181](https://github.com/moody/Dejunk/issues/181))
- Ability to sell/destroy heirloom quality items ([#187](https://github.com/moody/Dejunk/issues/187))
- New `itemId` param for global list functions ([#186](https://github.com/moody/Dejunk/issues/186))

### Fixed

- Typo in locale entry ([#180](https://github.com/moody/Dejunk/issues/180))
- Keybinds button error in Classic
- Loot command errors

## [1.6.1] - 2023-02-18

### Added

- Ability to add items to the Global Exclusions list via the Junk frame

### Changed

- Small visual changes to the tooltips for the Minimap and Merchant buttons

### Fixed

- Frequency of errors when opening a large amount of lootable items

## [1.6.0] - 2023-02-03

### Added

- Support for Global and Character lists (i.e. both are now active at all times)
- New keybindings to support Global and Character lists
- Added buttons to the list frames:
  - `Switch View` switches the view between Global and Character lists
  - `Transport` toggles the Transport frame for the displayed list

### Changed

- Active lists are no longer tied to `Options > Character Specific Settings`
- Command `/dejunk transport {inclusions|exclusions}` now requires an additional argument: `/dejunk transport {inclusions|exclusions} {global|character}`
- Holding `Shift` when dropping an item into the Junk frame will add it to `Inclusions (Global)`
- Mousing over the `Destroy Next Item` button on the Junk frame now displays the item's tooltip by default

## [1.5.1] - 2023-01-27

### Changed

- Split the dual-functionality of the Junk Frame button into two distinct buttons: `Start Selling` & `Destroy Next Item`
- Added tooltips to the Junk Frame's `Destroy Next Item` button: mousing over the button will display the name of the next item to be destroyed, and holding shift will display the item's tooltip

### Fixed

- Issue with frame levels
- Support for reagent bag in retail ([#165](https://github.com/moody/Dejunk/issues/165))

## [1.5.0] - 2023-01-27

### Added

- Option: `Exclude Unbound Equipment`
- Option: `Include Artifact Relics` ([#106](https://github.com/moody/Dejunk/issues/106))

### Changed

- Updated the merchant button to support ElvUI
- Reverted behavior of option `Auto Junk Frame` to no longer apply to bags

### Fixed

- Issues with minimap icon positioning ([#163](https://github.com/moody/Dejunk/issues/163))
- Issues with bag item caching
- Taint with keybinding UI ([#166](https://github.com/moody/Dejunk/issues/166))

## [1.4.1] - 2022-11-04

### Fixed

- Option: `Auto Junk Frame` support for AdiBags, ArkInventory, Bagnon, and ElvUI ([#158](https://github.com/moody/Dejunk/issues/158))
- Potential error related to accessing saved variables before they are ready ([#159](https://github.com/moody/Dejunk/issues/159))

## [1.4.0] - 2022-11-03

### Added

- Option: `Include Below Item Level`
- Additional tooltips and `OnClick` handling for List Frame and Junk Frame item buttons ([#144](https://github.com/moody/Dejunk/issues/144))

### Changed

- Updated option buttons to contain a checkbox visual
- Reverted change to Merchant Button point ([#155](https://github.com/moody/Dejunk/issues/155))

### Removed

- Option: `Include Below Average Equipment`
- UI sound effects

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
