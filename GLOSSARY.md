# jig-image-picker Glossary

A picker that lets you choose an image in a folder from a list and puts it on the clipboard. This file fixes what its concepts are called.
Identifiers are built from these terms (remove the spaces: Settings File → SettingsFile, Key Chord → KeyChord).
Nested fields drop the parent's word (Item Layout's Thumbnail Size → itemLayout.thumbnailSize).

## Settings

- Settings File: The YAML file the settings are written in. Holds the list of profiles and the default profile name
- Profile: A full set of settings per Entry Sources. One is chosen by name at launch, and the app uses it
- Default Profile: The profile used when no name is given
- Window Size: The width and height of the window at launch
- Arguments: The arguments at launch. A profile name, --check, and overrides for Profile fields (Entry Source, Sort Order, Clipboard Content Type, Item Layout). Option names are the kebab case of the field names (--sort-order). Profile's nesting (Entry Source, Item Layout) is nested the same way in Arguments (Entry Source Arguments, Item Layout Arguments)

## Entry

- Entry: One image file shown in the list. Has a location, a name, and a modification date
- Entries: The sequence of Entries collected from Entry Sources
- Entry Source: One place Entries are collected from. Its kind is chosen with Entry Source Type. Where to collect from is held per kind
- Entry Sources: A sequence of Entry Sources. A Profile has one or more, and Entries are collected from all of them and merged into one (the same file appears once). entrySources in the Settings File
- Entry Source Type: One of directory (a folder; has path, its path, and recursive, whether to also look at the folders beneath it), smartFolder (a Smart Folder; has path, the path of its .savedSearch), or spotlightSearch (a Spotlight Search; has its query and scopes). type in the Settings File
- Sort Order: The order of Entries (newest / oldest / name / nameDescending)

## Spotlight Search

- Spotlight Search: What Spotlight is asked to find with a Spotlight Search Query and Spotlight Search Scopes
- Spotlight Search Query: The search query passed to Spotlight. RawQuery in a .savedSearch
- Spotlight Search Scopes: The range to search. A folder path (~ allowed) or a constant name such as the whole Mac (kMDQueryScopeHome, etc.). SearchScopes in a .savedSearch
- Smart Folder: A Finder smart folder (.savedSearch). A file that saves a Spotlight Search

## Filter

- Entry Name Filter: Narrowing down to only the Entries whose file name contains the Filter Text
- Filter Text: The string typed into the filter field
- Filter Field: The field where the Filter Text is typed

## Item

- Item: One cell in the list. Made of a Thumbnail and Item Info
- Item Info: The file name and modification date shown in the cell
- Thumbnail: The reduced image shown in the cell
- Thumbnail Size: The length of one side of the Thumbnail (px)
- Thumbnail Content Mode: How the Thumbnail fits into the cell. fit (shrink so the whole image fits) or fill (expand the short side to fill the cell and crop the long side)
- Item Layout: Thumbnail Size, Thumbnail Content Mode, whether Item Info is shown, and the cell dimensions derived from them
- Date Format: The format and locale of the modification date in Item Info

## Key

- Action: An operation performed by a key (copy / cancel / quickLook / trash / previous / next / previousRow / nextRow)
- Key Chord: The combination of keys pressed. A key and modifier keys
- Key Name: The string for a key written in the settings ("cmd+y", etc.)
- Key Bindings: The table that looks up an Action from a Key Chord. Written as Key Name → Action in the Settings File

## Quick Look

- Quick Look: Showing the selected Entry large in the macOS Quick Look panel. While it is open, only some Actions work

## Clipboard

- Clipboard Content Type: The kind of thing a copy puts on the clipboard. image (image data) / file (file reference) / path (path string)

## Notice

- Failure Notice: Showing the reason when copying or moving to the Trash fails

## Terms Not Used

- Config: Settings are called Settings. config is used only in file and directory names on disk (config/, ~/.config/, config.yaml)
- Target: The profile being chosen is called a Profile
- Pasteboard: The clipboard is called the Clipboard. It remains only in the AppKit type name NSPasteboard
