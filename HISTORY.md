# 9.0.6

## Changes to Destroying

As of Shadowlands patch 9.0.2, addons can no longer destroy items at will.
Addons may only destroy items in response to a hardware event.
So, Dejunk's destroy functionality has been reworked.

Previously, you could have Dejunk destroy items by:

- Enabling `Destroy > General > Auto Destroy`
- Clicking the `Start Destroying` button in the options frame
- **Right**-Clicking the minimap icon
- Running the command `/dejunk destroy`
- Using a keybind

Now, Dejunk can only destroy items _one at a time_ in two ways:

- Interacting with the new Destroy frame
- Using a keybind

## Additions

- Added a Sell frame to display current items that will be sold.
  Open the frame by:

  - Clicking the `Toggle Sell Frame` button in the options frame
  - **Shift Left**-Clicking the minimap button
  - Running the command `/dejunk sell`
  - Using a keybind

- Added a Destroy frame to display current items that will be destroyed.
  Open the frame by:
  - Enabling `Destroy > General > Auto Open`
  - Clicking the `Toggle Destroy Frame` button in the options frame
  - **Shift Right**-Clicking the minimap button
  - Running the command `/dejunk destroy`
  - Using a keybind

## Changes

- Replaced `Destroy > General > Auto Destroy` with `Auto Open` which will
  automatically open the Destroy frame when destroyable items are found
- Reduced min-max values for `Sell > By Type > Below Average Item Level` to
  2-50 (was 10-100)

# 9.0.5

## Fixes

- Fixed compatibility with LibDataBroker add-ons, such as Titan Panel ([#77](https://github.com/moody/Dejunk/issues/77))

## Changes

- `General > Chat > Reason` option is now enabled by default
- `Sell > Ignore` and `Destroy > Ignore` options are now enabled by default

# 9.0.4

## Changes

- Due to increasing complexity and bug potential, the database has been changed.
  During the transition, all existing settings will be reset to default, but
  lists will remain.

# 9.0.3

## Changes

- Due to oversight, the change which made chat options global has been reverted

# 9.0.2

## Changes

- Chat options are now global and apply across all characters

## Additions

- Added option `General > Global > Chat > Frame` to specify which chat frame to output messages to ([#61](https://github.com/moody/Dejunk/issues/61))
- Added option `General > Global > Chat > Reason` to output the reason why an item was sold or destroyed

# 9.0.1

## Changes

- Reason messages displayed in Dejunk tooltips now point directly to the corresponding option
- Removed need for `Destroy > General > Save Space` check button

## Fixes

- Minor bug fixes

# 9.0.0

Updated for Shadowlands pre-patch.

## Additions

- Added command `/dejunk toggle` to toggle the user interface
- Added command `/dejunk sell` to start selling items
- Added command `/dejunk destroy` to start destroying items
- Added command `/dejunk open` to start opening lootable items
