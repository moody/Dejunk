# Changelog

## [3.1.0] - 2026-09-23

### Added

- A way to reset any profile to its default settings: Shift+Right-click it in the Profiles Frame.

### Changed

- The `Default` profile now behaves like any other profile: it saves your changes directly instead of always creating a new one, and it's used automatically by any character with no profile assigned, or whose assigned profile was deleted. It still cannot be renamed or deleted.

### Fixed

- The merchant button's label could get stuck showing "..." instead of its full text.

### Removed

- The one-time migration that converted lists from Dejunk 2.x's old SavedVariables shape. Updating directly from a 2.x version no longer carries your lists over automatically.
