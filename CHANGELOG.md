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
