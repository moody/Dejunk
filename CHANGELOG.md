# Changelog

## [2.0.8] - 2025-08-06

### Fixed

- Error when selling tradable items in Retail ([#248](https://github.com/moody/Dejunk/issues/248))

## [2.0.7] - 2025-08-05

### Fixed

- Resolved errors with popup code for 11.2.0

## [2.0.6] - 2025-08-02

- Updated suitable items table for MoP Classic

## [2.0.5] - 2025-07-08

- Version updates

## [2.0.4] - 2025-03-01

### Changed

- Updated the Merchant Button to be attached to the merchant frame ([#236](https://github.com/moody/Dejunk/issues/236))

## [2.0.3] - 2024-12-24

### Fixed

- Addon out of date errors

## [2.0.2] - 2024-10-03

### Fixed

- Minimap icon compatibility with HidingBar ([#232](https://github.com/moody/Dejunk/issues/232))

## [2.0.1] - 2024-10-01

### Changed

- Updated item buttons on the Junk Frame to destroy the item using `Alt + Right-Click`
- Updated the Merchant Button to perform the `Destroy Next Item` action using `Alt + Right-Click`
- Updated the Minimap Icon to perform the `Destroy Next Item` action using `Alt + Right-Click` (was `Shift + Left-Click`)
- Updated tooltips for the Merchant Button and Minimap Icon to display the next destroyable junk item while holding `Alt`

## [2.0.0] - 2024-09-28

### Added

- Addon compartment support for retail
- Option: `Exclude Warband Equipment` for retail
- Option: `Include By Quality` with check boxes for item qualities

### Removed

- Option: `Include Poor Items` in favor of `Include By Quality`

### Changed

- Merchant Button is now draggable
- Left-Click on Merchant Button initiates selling
- Right-Click on Merchant Button toggles the Options Frame
- Shift + Left-Click on Merchant Button toggles the Junk Frame
- Positions of draggable frames are now saved globally
- Shift + Right-Click on a draggable frame will reset its position
- Items listed in the Junk Frame no longer have a price displayed when they have no value
- Opening the Transport Frame now automatically exports the associated list
- Right-Clicking the `Include Below Item Level` option is now required to change the value
- Option: `Exclude Unbound Equipment` to have additional check boxes for item quality
- Option: `Include Below Item Level` to apply to equipment regardless of bound status, as well as to have additional check boxes for item quality
- Option: `Include Unsuitable Equipment` to apply to equipment regardless of bound status, as well as to have additional check boxes for item quality

### Fixed

- Resolved a bug which caused refundable junk items to not be ignored

## [1.10.8] - 2024-08-21

### Fixed

- Fixed a bug that would sometimes prevent the bag items cache from updating (hopefully)

## [1.10.7] - 2024-08-21

### Fixed

- Performance issues when loading large lists ([#222](https://github.com/moody/Dejunk/issues/222))
- Attempted to fix an unknown issue with the bag cache by periodically updating it

## [1.10.6] - 2024-07-27

### Fixed

- Item icons when using combined bags in retail ([#219](https://github.com/moody/Dejunk/issues/219))

## [1.10.5] - 2024-07-26

### Fixed

- TOC version for classic
- Item icons on retail ([#219](https://github.com/moody/Dejunk/issues/219))
- Increased looter interval ([#212](https://github.com/moody/Dejunk/issues/212))

## [1.10.4] - 2024-07-25

### Changed

- Command: `/dejunk` - Toggle the options frame
- Command: `/dejunk help` - Display a list of commands

## [1.10.3] - 2024-05-16

### Changed

- The following options are now applied globally:

  1. `Bag Item Icons`
  2. `Bag Item Tooltips`
  3. `Chat Messages`
  4. `Merchant Button`

- Added headings to group UI options together

## [1.10.2] - 2024-05-13

### Changed

- When the `Below Item Level` and `Unsuitable Equipment` options are enabled, certain "Cosmetic" items should now be properly ignored ([#209](https://github.com/moody/Dejunk/issues/209))

## [1.10.1] - 2024-05-12

### Changed

- Attempted bug fix for improperly placed item icons on Bagnon frames

## [1.10.0] - 2024-05-11

### Added

- Option: `Bag Item Icons` ([#167](https://github.com/moody/Dejunk/issues/167))

### Changed

- For Cataclysm, updated the handling of unsuitable armor when the player is below level 50

## [1.9.2] - 2024-05-07

### Changed

- Listeners registered using `DejunkApi:AddListener(listener)` now receive an `event` argument equal to one of the following values:

  1. `DejunkApi.Events.BagsUpdated` when Dejunk updates its internal bag cache
  2. `DejunkApi.Events.StateUpdated` when Dejunk's state has changed (e.g., the user changes an option, adds an item to a list, etc.)

- Modified the default value for `Exclude Equipment Sets` to be `true`, regardless of game version
- Modified the default value for `Exclude Unbound Equipment` to be `false`, regardless of game version

## [1.9.1] - 2024-05-06

### Added

- Global API Methods: `DejunkApi:AddListener(listener)` and `DejunkApi:IsJunk(bagId, slotId)` ([#189](https://github.com/moody/Dejunk/issues/189))

### Changed

- Refactored the `Keybinds` button to use an icon
- Removed outdated code (Container)

## [1.9.0] - 2024-05-04

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
