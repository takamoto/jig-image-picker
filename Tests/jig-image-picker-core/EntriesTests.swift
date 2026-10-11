import Foundation
import Testing

@testable import JigImagePickerCore

private func entry(_ name: String, at seconds: TimeInterval) -> Entry {
  Entry(
    url: URL(fileURLWithPath: "/pics/\(name)"), name: name,
    modified: Date(timeIntervalSince1970: seconds))
}

@Suite struct Arranging {
  let entries = [entry("img10.png", at: 20), entry("img2.png", at: 30), entry("a.png", at: 10)]

  @Test func byDate() {
    #expect(entries.arranged(by: .newest).map(\.name) == ["img2.png", "img10.png", "a.png"])
    #expect(entries.arranged(by: .oldest).map(\.name) == ["a.png", "img10.png", "img2.png"])
  }

  @Test func byNameIsNumericAware() {
    #expect(entries.arranged(by: .name).map(\.name) == ["a.png", "img2.png", "img10.png"])
    #expect(
      entries.arranged(by: .nameDescending).map(\.name) == ["img10.png", "img2.png", "a.png"])
  }
}

@Suite struct Filtering {
  let entries = [
    entry("Screenshot 1.png", at: 1), entry("screenshot 2.png", at: 2),
    entry("photo.jpg", at: 3),
  ]

  @Test func emptyOrBlankQueryKeepsAll() {
    #expect(entries.filtered(byName: "") == entries)
    #expect(entries.filtered(byName: "   ") == entries)
  }

  @Test func isCaseSensitive() {
    #expect(entries.filtered(byName: "Screen").map(\.name) == ["Screenshot 1.png"])
    #expect(entries.filtered(byName: "screen").map(\.name) == ["screenshot 2.png"])
    #expect(entries.filtered(byName: "SCREEN").isEmpty)
  }

  @Test func surroundingWhitespaceIsIgnored() {
    #expect(entries.filtered(byName: " photo ").map(\.name) == ["photo.jpg"])
  }
}

@Suite struct EntrySourceSettings {
  @Test func smartFolderType() throws {
    let profile = try testProfile(
      "entrySources: [{ type: smartFolder, path: /searches/all.savedSearch }]")
    #expect(profile.entrySources == [.smartFolder(path: "/searches/all.savedSearch")])
  }

  @Test func spotlightSearchType() throws {
    let profile = try testProfile(
      "entrySources: [{ type: spotlightSearch, query: 'kMDItemFSName == \"*.png\"', scopes: [~/Pictures, kMDQueryScopeHome] }]"
    )
    #expect(
      profile.entrySources == [
        .spotlightSearch(
          query: "kMDItemFSName == \"*.png\"",
          scopes: ["~/Pictures", "kMDQueryScopeHome"])
      ])
  }

  @Test func missingQueryFails() {
    let message = errorMessage {
      try testProfile(
        "entrySources: [{ type: spotlightSearch, scopes: [kMDQueryScopeHome] }]")
    }
    #expect(message == "missing item: profiles.test.entrySources[0].query")
  }

  @Test func missingScopesFail() {
    let message = errorMessage {
      try testProfile("entrySources: [{ type: spotlightSearch, query: 'x == 1' }]")
    }
    #expect(message == "missing item: profiles.test.entrySources[0].scopes")
  }

  @Test func emptyScopesFail() {
    let message = errorMessage {
      try testProfile(
        "entrySources: [{ type: spotlightSearch, query: 'x == 1', scopes: [] }]")
    }
    #expect(message == "profiles.test.entrySources[0].scopes: empty")
  }

  @Test func unknownTypeFails() {
    let message = errorMessage {
      try testProfile("entrySources: [{ type: folder, path: /pics, recursive: false }]")
    }
    #expect(message?.hasPrefix("profiles.test.entrySources[0].type: ") == true)
  }

  @Test func missingTypeFails() {
    let message = errorMessage {
      try testProfile("entrySources: [{ path: /pics, recursive: false }]")
    }
    #expect(message == "missing item: profiles.test.entrySources[0].type")
  }

  @Test func missingPathFails() {
    let message = errorMessage { try testProfile("entrySources: [{ type: smartFolder }]") }
    #expect(message == "missing item: profiles.test.entrySources[0].path")
  }

  @Test func recursiveIsRequiredOnlyForDirectory() throws {
    let message = errorMessage {
      try testProfile("entrySources: [{ type: directory, path: /pics }]")
    }
    #expect(message == "missing item: profiles.test.entrySources[0].recursive")
    #expect(
      try testProfile("entrySources: [{ type: smartFolder, path: /x.savedSearch }]")
        .entrySources.count == 1)
  }
}

@Suite struct LoadingFromDisk {
  /// Puts a.png, b.PNG, c.txt, .hidden.png and sub/d.png in the scratch folder.
  private func makeTree() throws -> URL {
    let root = scratchDirectory().appendingPathComponent("image-picker-\(UUID())")
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("sub"), withIntermediateDirectories: true)
    for name in ["a.png", "b.PNG", "c.txt", ".hidden.png", "sub/d.png"] {
      try Data([0x89]).write(to: root.appendingPathComponent(name))
    }
    return root
  }

  private func source(_ directory: URL, recursive: Bool = false) -> EntrySource {
    .directory(path: directory.path, recursive: recursive)
  }

  @Test func imagesInDirectory() throws {
    let root = try makeTree()
    defer { try? FileManager.default.removeItem(at: root) }
    let names = Entry.load(from: source(root)).arranged(by: .name).map(\.name)
    #expect(names == ["a.png", "b.PNG"])
  }

  @Test func recursive() throws {
    let root = try makeTree()
    defer { try? FileManager.default.removeItem(at: root) }
    let names = Entry.load(from: source(root, recursive: true)).arranged(by: .name).map(\.name)
    #expect(names == ["a.png", "b.PNG", "d.png"])
  }

  @Test func missingDirectoryYieldsNothing() {
    let missing = URL(fileURLWithPath: "/nonexistent/\(UUID())")
    #expect(Entry.load(from: source(missing)).isEmpty)
  }

  /// No test hits Spotlight (it does not work on an unindexed scratch folder). Only an unreadable .savedSearch is checked.
  @Test func missingSmartFolderYieldsNothing() {
    let missing = "/nonexistent/\(UUID()).savedSearch"
    #expect(Entry.load(from: .smartFolder(path: missing)).isEmpty)
  }
}

@Suite struct LoadingFromSources {
  /// Puts one file called name in the scratch folder.
  private func makeDirectory(containing name: String) throws -> URL {
    let root = scratchDirectory().appendingPathComponent("image-picker-\(UUID())")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try Data([0x89]).write(to: root.appendingPathComponent(name))
    return root
  }

  @Test func sourcesAreJoinedInWrittenOrder() throws {
    let first = try makeDirectory(containing: "a.png")
    let second = try makeDirectory(containing: "b.png")
    defer {
      try? FileManager.default.removeItem(at: first)
      try? FileManager.default.removeItem(at: second)
    }
    let sources: [EntrySource] = [
      .directory(path: second.path, recursive: false),
      .directory(path: first.path, recursive: false),
    ]
    #expect(Entry.load(from: sources).map(\.name) == ["b.png", "a.png"])
  }

  @Test func sameFileAppearsOnce() throws {
    let root = try makeDirectory(containing: "a.png")
    defer { try? FileManager.default.removeItem(at: root) }
    let source = EntrySource.directory(path: root.path, recursive: false)
    #expect(Entry.load(from: [source, source]).map(\.name) == ["a.png"])
  }

  @Test func noSourcesYieldNothing() {
    #expect(Entry.load(from: []).isEmpty)
  }
}
