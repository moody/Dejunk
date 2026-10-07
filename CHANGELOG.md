# Changelog

## [3.3.0] - Unreleased

### Added

- Added `Exclude Above Price` and `Include Below Price`, which compare the price of an item's whole stack with a set value. Each applies to selling, destroying, or both: `Include Below Price` starts on selling and `Exclude Above Price` on destroying. Items with no vendor price are never affected. Like `Exclude Above Item Level`, `Exclude Above Price` takes priority over Inclusions lists.
- Added `Include By Equipment Type` and `Exclude By Equipment Type`, which apply to equipment of the selected armor and weapon types and qualities, with the types shown as columns of checkboxes. Cloaks never match.
- Added an `Applies To` setting to `Include By Quality`, `Include Below Item Level`, `Include By Equipment Type`, `Exclude Above Item Level`, `Exclude By Equipment Type`, `Exclude Unbound Equipment`, and `Exclude Warband Equipment`, so each can apply to selling, destroying, or both. They start on both, which is how they worked before.
- Added a `Size` setting to `Bag Item Icons`: `Small` (the default) or `Large`, which covers the whole slot as it did before 3.2.0.

### Changed

- The main window now has a sidebar for switching between your lists, `Global Options`, and `Profile Options`. Each options page gets the whole window instead of sharing it with your lists.
- The options pages are split into groups: `General`, `Include`, and `Exclude` on `Profile Options`, and `Safety`, `Interface`, and `Bags` on `Global Options`.
- The lists search box now sits at the top of the lists, always visible, instead of opening in the title bar.
- Each option shows a short description under its name, and clicking anywhere on an option turns it on or off.
- Options with extra settings, such as an item level or item qualities, show them right under the option, faded while the option is off.
- Item quality checkboxes are labeled with each quality's name.
- Item tooltips show separate `Selling` or `Not Selling` and `Destroying` or `Not Destroying` verdicts, each with its reason, instead of one verdict.
- Item levels are typed straight into the option and saved as you type, instead of right-clicking the option to open a popup.
- Options that don't apply to generic, cosmetic, or fishing pole items are marked with an asterisk, explained by a note at the bottom of the page.
- `Toggle Options Frame` is now `Toggle Main Window` in the key bindings, the minimap icon tooltip, the AddOns settings page, and `/dejunk help`. Existing key bindings are kept.
- Item quality names and the `Alt`, `Ctrl`, and `Shift` key names now come from the game, so they match its language.

### Fixed

- `Bag Item Icons` did not appear in the default bags on WoW Forever.
- Items in the reagent bag were not scanned on WoW Forever, so junk in a bag in the reagent slot was never found.
- On WoW Forever, characters with the same first name and different last names shared a profile assignment, because only the first name was used. Affected characters may need their profile selected again.

### Removed

- Removed `Include Unsuitable Equipment` in favor of `Include By Equipment Type`.
