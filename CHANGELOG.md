# Changelog

## [Unreleased]

### Added

- Profiles. Each character has a profile holding its `Inclusions (Profile)` list, `Exclusions (Profile)` list, and its own copy of the character-specific options. Every character starts on the `Default` profile, whose lists cannot be edited directly; the first time you add an item to a profile list, Dejunk creates a profile for that character and switches to it. The active profile's name is printed to chat whenever it changes.
- A `Profiles` frame for managing profiles directly, opened via the gear icon in the main window's footer (which also shows the active profile's name). Profiles can be created, switched, renamed, and deleted from this frame. The `Default` profile cannot be renamed or deleted, and deleting the active profile switches back to `Default`.

### Changed

- The `Inclusions (Character)` and `Exclusions (Character)` lists are now named `Inclusions (Profile)` and `Exclusions (Profile)`. Existing lists carry over automatically.
- The options window is split into `Profile` and `Global` sections, each with a heading.
- Removed the `Character Specific Settings` option. The options it controlled are now always part of the active profile:
  1. `Auto Junk Frame`
  2. `Auto Repair`
  3. `Auto Sell`
  4. `Safe Mode`
  5. `Exclude Equipment Sets`
  6. `Exclude Unbound Equipment`
  7. `Exclude Warband Equipment`
  8. `Include Artifact Relics`
  9. `Include Below Item Level`
  10. `Include By Quality`
  11. `Include Unsuitable Equipment`

  If you had `Character Specific Settings` disabled and relied on a shared global value for any of these, set that option again on each character.

### Removed

- The `/dejunk keybinds` and `/dejunk transport` chat commands. Key bindings are still reachable from the keybinds button in the main window's title bar, and each list frame still has its own button for opening the transport frame.
