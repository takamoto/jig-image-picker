# jig-image-picker

A GUI picker for macOS that lets you choose an image from a list and puts it on the clipboard.
It does not stay resident: launch → pick → copy and quit.

## Usage

```sh
make install                    # Build and place at ~/.local/bin/jig-image-picker (change with BIN_DIR)
make test                       # Unit tests
make format                     # Format the sources with swift-format (settings in .swift-format)
make lint                       # Check the sources with swift-format
jig-image-picker --check        # Validate the settings without opening a window
jig-image-picker {profile name} # Launch with a profile name (see --help for all arguments)
```

Builds with SwiftPM from the Xcode Command Line Tools (macOS 14 or later).
When launching from a launcher, the launcher needs "Files and Folders" access (without it, images on the Desktop and elsewhere do not appear in the list).

## Settings

Written in `~/.config/jig-image-picker/config.yaml` (override with `JIG_IMAGE_PICKER_CONFIG`).
For the fields, see `Sources/jig-image-picker-core/SettingsFile.swift` and `Profile.swift`; for the terms, see `GLOSSARY.md`.
A sample with every field is in [`docs/config.example.yaml`](docs/config.example.yaml).

Where images are collected from (`entrySources`) is a list of one or more folders, Finder smart folders (`.savedSearch`), or Spotlight search queries.
They are collected in the order written, and the same file is merged into one.

```yaml
profiles:
  screenshots:
    entrySources:
      - type: directory
        path: ~/Pictures/Screenshots
        recursive: false
      - type: smartFolder
        path: ~/Library/Saved Searches/screenshots.savedSearch
      - type: spotlightSearch
        query: 'kMDItemIsScreenCapture == 1'
        scopes: [kMDQueryScopeHome]
```
