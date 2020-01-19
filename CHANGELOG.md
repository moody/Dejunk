# 8.3.0

## Changes

- Changed the "Sell/Destroy Below Price" options to be applied _after_ list filters when selling or destroying
  - So, an item on Inclusions/Destroyables will now be sold/destroyed regardless of this option's settings

## Additions

- Added an **Undestroyables** list for items to never destroy
- Added destroy options for Common, Uncommon, Rare, and Epic quality items
- Added destroy options for ignoring items based on category and type
- Added sell option for ignoring reagent items
- Added ability to sort lists by Class, Name, Price, or Quality (default)

## Removals

- Removed the "Ignore Exclusions" destroy option
  - Profiles which used this option will automatically have Exclusions added to the new Undestroyables list
- Removed the "Destroy Inclusions" destroy option
  - For safety reasons, profiles which used this option will **not** automatically have Inclusions added to Destroyables

## Fixes

- Fixed a tooltip bug affecting certain types of items
