# Changelog

## [3.6.0] - Unreleased

### Added

- Added a `Log` screen to the main window, opened with `/dejunk log`. It lists what Dejunk sold or destroyed this session, newest first, with the reason each item was junk, how long ago it happened, and its value. Items that failed to sell or destroy, or that may not have, are listed too, in grey. Tabs show all entries, only selling, or only destroying, and a line under the list totals the items sold, the profit, and the items destroyed. The log is cleared when the game reloads.
- Added an `Expendable Items` frame that lists the bag items you could destroy to make room, cheapest stack first, so you can free a slot in a few clicks. Items Dejunk considers junk for destroying are always listed, with a black and white icon, and items excluded from destroying never are. Other items are listed only if their type (`Equipment`, `Trade Goods`, `Consumables`, or `Other`) and quality are selected in the frame's options. A `Free Slots` heading shows how many free slots your bags have, and each item has an Exclude and a Destroy button.
- Added an `Auto Show` choice for the Expendable Items frame: `Never`, `Bags Full`, `On Error`, or `Always`. `Bags Full` shows it when your bags are full while the loot window is open, and is the default. `On Error` shows it when the game says your inventory is full. `Always` shows it whenever the loot window opens. `Bags Full` and `Always` hide it when the loot window closes, and `Never` and `On Error` leave it for you to close.
- Added `/dejunk expendable` and a `Toggle Expendable Items Frame` keybinding.

### Changed

- The Junk Items, Lootable Items, and Expendable Items frames show a stack's count on the item's icon, instead of after its link.
- Every Dejunk window/frame now shows the Dejunk icon beside its title, not just the main window.

### Fixed

- Fixed bag item icons being missing or in the wrong bag with ElvUI on WoW Forever.
