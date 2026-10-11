import Foundation
import Testing
import Yams

@testable import JigImagePickerCore

@Suite struct ProfileValues {
  @Test func profileOverridesDefaults() throws {
    let s = try testProfile(
      """
      itemLayout: { <<: *itemLayout, thumbnailContentMode: fill }
      window: { <<: *window, height: 300 }
      keyBindings: { <<: *keyBindings, cmd+delete: cancel, ctrl+f: next }
      """)
    #expect(s.itemLayout.thumbnailContentMode == .fill)
    // Nested items overlay the same way via their anchor (only height changes, width stays)
    #expect(s.window == WindowSize(width: 960, height: 300))
    // Keys can be rebound and added (but not removed)
    #expect(s.keyBindings[KeyChord(keyName: "return")!] == .copy)
    #expect(s.keyBindings[KeyChord(keyName: "cmd+delete")!] == .cancel)
    #expect(s.keyBindings[KeyChord(keyName: "ctrl+f")!] == .next)
  }

  @Test func defaultKeysAreBound() throws {
    let s = try testProfile()
    #expect(s.keyBindings[KeyChord(keyName: "enter")!] == .copy)
    #expect(s.keyBindings[KeyChord(keyName: "escape")!] == .cancel)
    #expect(s.keyBindings[KeyChord(keyName: "ctrl+n")!] == .nextRow)
    #expect(s.keyBindings.count == 11)
  }

  @Test func unknownEnumValueFails() {
    let message = errorMessage { try testProfile("sortOrder: random") }
    #expect(message?.contains("sortOrder") == true)
    #expect(errorMessage { try testProfile("clipboardContentType: url") } != nil)
    #expect(
      errorMessage {
        try testProfile("itemLayout: { <<: *itemLayout, thumbnailContentMode: stretch }")
      } != nil)
  }

  @Test func missingItemFails() {
    // A profile that forgot <<: *defaults
    let yaml =
      defaultsYAML + "defaultProfile: test\nprofiles:\n  test:\n    sortOrder: newest\n"
    let message = errorMessage { try SettingsFile(yaml: yaml) }
    #expect(message?.hasPrefix("missing item: profiles.test.") == true)
  }

  @Test func directoryKeepsPathAsWritten() throws {
    let profile = try testProfile(
      "entrySources: [{ type: directory, path: ~/Pictures, recursive: false }]")
    #expect(profile.entrySources == [.directory(path: "~/Pictures", recursive: false)])
  }

  @Test func entrySourcesKeepWrittenOrder() throws {
    let profile = try testProfile(
      "entrySources: [{ type: smartFolder, path: /all.savedSearch }, { type: directory, path: /shots, recursive: true }]"
    )
    #expect(
      profile.entrySources == [
        .smartFolder(path: "/all.savedSearch"), .directory(path: "/shots", recursive: true),
      ])
  }

  @Test func emptyEntrySourcesFail() {
    #expect(
      errorMessage { try testProfile("entrySources: []") }
        == "profiles.test.entrySources: empty")
  }

  @Test func missingEntrySourcesFail() {
    // A profile that leaves out only entrySources
    let yaml =
      defaultsYAML + """
        defaultProfile: test
        profiles:
          test:
            sortOrder: newest
            itemLayout: *itemLayout
            dateFormat: *dateFormat
            window: *window
            clipboardContentType: image
            keyBindings: *keyBindings

        """
    #expect(
      errorMessage { try SettingsFile(yaml: yaml) }
        == "missing item: profiles.test.entrySources")
  }
}

@Suite struct ProfileDescription {
  @Test func dumpsAsYAMLInSettingsFileShape() throws {
    let profile = try testProfile(
      """
      entrySources: [{ type: directory, path: ~/shots, recursive: false }]
      itemLayout: { <<: *itemLayout, thumbnailContentMode: fill }
      keyBindings: { return: copy, keypadenter: copy, esc: cancel }
      """)
    // Same keys and order as the settings file. Sizes in px are integers, not 2.0e+2.
    // Key names are canonical (keypadenter -> enter, esc -> escape) and sorted.
    #expect(
      profile.description == """
        entrySources:
        - type: directory
          path: ~/shots
          recursive: false
        sortOrder: newest
        itemLayout:
          thumbnailSize: 200
          thumbnailContentMode: fill
          showItemInfo: true
        dateFormat:
          format: yyyy/MM/dd HH:mm:ss
          locale: ja_JP
        window:
          width: 960
          height: 640
        clipboardContentType: image
        keyBindings:
          enter: copy
          escape: cancel
          return: copy
        """)
  }

  @Test func listsEntrySourcesInWrittenOrder() throws {
    let profile = try testProfile(
      "entrySources: [{ type: smartFolder, path: /all.savedSearch }, { type: directory, path: /shots, recursive: true }]"
    )
    #expect(
      profile.description.hasPrefix(
        """
        entrySources:
        - type: smartFolder
          path: /all.savedSearch
        - type: directory
          path: /shots
          recursive: true
        sortOrder: newest

        """))
  }

  @Test func dumpsSpotlightSearchAndReadsItBack() throws {
    let profile = try testProfile(
      "entrySources: [{ type: spotlightSearch, query: 'kMDItemFSName == \"*.png\"', scopes: [~/Pictures, kMDQueryScopeHome] }]"
    )
    #expect(
      profile.description.hasPrefix(
        """
        entrySources:
        - type: spotlightSearch
          query: kMDItemFSName == "*.png"
          scopes:
          - ~/Pictures
          - kMDQueryScopeHome
        sortOrder: newest

        """))
    let decoded = try YAMLDecoder().decode(Profile.self, from: profile.description)
    #expect(decoded.entrySources == profile.entrySources)
  }

  @Test func roundTripsThroughDecoder() throws {
    let profile = try testProfile("window: { <<: *window, height: 300.5 }")
    let decoded = try YAMLDecoder().decode(Profile.self, from: profile.description)
    #expect(decoded.window == WindowSize(width: 960, height: 300.5))
    #expect(decoded.keyBindings == profile.keyBindings)
    #expect(decoded.entrySources == profile.entrySources)
  }
}
