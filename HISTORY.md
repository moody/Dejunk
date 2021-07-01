# Dejunk History

## 9.0.15

- Removed the "Destroy All Items" keybind in favor of "Start Destroying"
- Removed the `/dejunk destroy all` command in favor of `/dejunk destroy start`
- Added "Sell > Auto Open" option, which automatically opens/closes the Sell frame upon opening a merchant window
- Updated the functionality of the Sell/Destroy frame buttons to "Start Selling/Destroying" instead of "Sell/Destroy Next Item" (items can still be sold/destroyed one at a time by left-clicking them)
- The Sell/Destroy frames will now retain their positions upon reloading the UI, and will be closed upon pressing the Escape key

## 9.0.14

- Added support for Burning Crusade Classic
- Updated the "Sell/Destroy Next Item" buttons to allow closing their respective
  frames if there are no items to display ([#100](https://github.com/moody/Dejunk/issues/100))

## 9.0.12

- Added global inclusion and exclusion lists
  - When selling or destroying, global lists are considered after the equivalent lists of the currently active profile

## 9.0.11

- Removed `Sell > By Type > Below Average Item Level`
- Added `Sell/Destroy > By Type > Item Level Range` options ([#56](https://github.com/moody/Dejunk/issues/56))
- Added `General > Chat > Sell/Destroy` options
- Added command:
  - `/dejunk destroy all` - destroys all items at once

## 9.0.10

- Minor bug fixes
- Locale updates

## 9.0.9

- `General > Chat > Verbose` and `General > Chat > Reason` are now disabled by default.
- **Right-Clicking** the minimap icon will now either:
  - Destroy Next Item (Retail)
  - Start Destroying (Classic)
- Re-added `Destroy > General > Auto Start` option for Classic (See [#87](https://github.com/moody/Dejunk/issues/87))
- Re-added `Start Selling` keybind (See [#89](https://github.com/moody/Dejunk/issues/89))
- Re-added `Start Destroying` keybind (Classic only)
- Added commands:
  - `/dejunk sell start` - starts the selling process
  - `/dejunk sell next` - sells the next item
  - `/dejunk destroy start` - starts the destroying process (Classic only)
  - `/dejunk destroy next` - destroys the next item

## 9.0.8

### Changes

- Locale updates

## 9.0.7

### Changes

- Locale updates
- Minor bug fixes

## 9.0.6

### Changes to Destroying

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

### Additions

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

### Changes

- Replaced `Destroy > General > Auto Destroy` with `Auto Open` which will
  automatically open the Destroy frame when destroyable items are found
- Reduced min-max values for `Sell > By Type > Below Average Item Level` to
  2-50 (was 10-100)

## 9.0.5

### Fixes

- Fixed compatibility with LibDataBroker add-ons, such as Titan Panel ([#77](https://github.com/moody/Dejunk/issues/77))

### Changes

- `General > Chat > Reason` option is now enabled by default
- `Sell > Ignore` and `Destroy > Ignore` options are now enabled by default

## 9.0.4

### Changes

- Due to increasing complexity and bug potential, the database has been changed.
  During the transition, all existing settings will be reset to default, but
  lists will remain.

## 9.0.3

### Changes

- Due to oversight, the change which made chat options global has been reverted

## 9.0.2

### Changes

- Chat options are now global and apply across all characters

### Additions

- Added option `General > Global > Chat > Frame` to specify which chat frame to output messages to ([#61](https://github.com/moody/Dejunk/issues/61))
- Added option `General > Global > Chat > Reason` to output the reason why an item was sold or destroyed

## 9.0.1

### Changes

- Reason messages displayed in Dejunk tooltips now point directly to the corresponding option
- Removed need for `Destroy > General > Save Space` check button

### Fixes

- Minor bug fixes

## 9.0.0

Updated for Shadowlands pre-patch.

### Additions

- Added command `/dejunk toggle` to toggle the user interface
- Added command `/dejunk sell` to start selling items
- Added command `/dejunk destroy` to start destroying items
- Added command `/dejunk open` to start opening lootable items
