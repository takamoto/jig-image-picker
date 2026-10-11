import Foundation
import Testing

@testable import JigImagePickerCore

/// Bytes of a plist shaped like a .savedSearch.
private func plist(_ dictionary: [String: Any]) throws -> Data {
  try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
}

@Suite struct SmartFolderParsing {
  @Test func queryAndScopesComeFromRawQueryDict() throws {
    let folder = try SmartFolder(
      plist: plist([
        "RawQuery": "kMDItemKind = 'old'",
        "RawQueryDict": [
          "RawQuery": "_kMDItemGroupId = 13",
          "SearchScopes": ["/Users/x/Pictures", "/Volumes/y"],
          "UserFilesOnly": false,
        ] as [String: Any],
        "SearchCriteria": ["FXScopeArrayOfPaths": ["kMDQueryScopeComputer"]]
          as [String: Any],
      ]))
    #expect(
      folder.search
        == SpotlightSearch(
          query: "_kMDItemGroupId = 13", scopes: ["/Users/x/Pictures", "/Volumes/y"]))
  }

  @Test func userFilesOnlyIsApproximated() throws {
    let folder = try SmartFolder(
      plist: plist([
        "RawQueryDict": [
          "RawQuery": "_kMDItemGroupId = 13",
          "SearchScopes": ["kMDQueryScopeComputer"],
          "UserFilesOnly": true,
        ] as [String: Any]
      ]))
    #expect(
      folder.search.query
        == "(_kMDItemGroupId = 13) && (kMDItemSupportFileType != \"MDSystemFile\")")
    #expect(folder.search.scopes == ["kMDQueryScopeComputer"])
  }

  @Test func fallsBackToTopLevelQueryAndFinderScopes() throws {
    let folder = try SmartFolder(
      plist: plist([
        "RawQuery": "kMDItemKind = 'image'",
        "SearchCriteria": ["FXScopeArrayOfPaths": ["/Users/x/Pictures"]] as [String: Any],
      ]))
    #expect(
      folder.search
        == SpotlightSearch(query: "kMDItemKind = 'image'", scopes: ["/Users/x/Pictures"]))
  }

  @Test func noScopesMeansWholeComputer() throws {
    let folder = try SmartFolder(plist: plist(["RawQuery": "kMDItemKind = 'image'"]))
    #expect(folder.search.scopes == ["kMDQueryScopeComputer"])
  }

  @Test func missingRawQueryFails() throws {
    let data = try plist(["RawQueryDict": ["UserFilesOnly": true] as [String: Any]])
    #expect(errorMessage { try SmartFolder(plist: data) } == "missing RawQuery")
  }

  @Test func nonPlistFails() {
    #expect(
      errorMessage { try SmartFolder(plist: Data("not a plist".utf8)) } == "not a valid plist"
    )
  }
}

@Suite struct SmartFolderReading {
  @Test func fileIsRead() throws {
    let url = scratchDirectory().appendingPathComponent("image-picker-\(UUID()).savedSearch")
    try plist(["RawQuery": "kMDItemKind = 'image'"]).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    #expect(
      try SmartFolder(contentsOf: url).search
        == SpotlightSearch(
          query: "kMDItemKind = 'image'", scopes: ["kMDQueryScopeComputer"]))
  }

  @Test func brokenFileFails() throws {
    let url = scratchDirectory().appendingPathComponent("image-picker-\(UUID()).savedSearch")
    try Data("broken".utf8).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    #expect(
      errorMessage { try SmartFolder(contentsOf: url) }
        == "\(url.lastPathComponent): not a valid plist")
  }

  @Test func missingFileFails() {
    let url = URL(fileURLWithPath: "/nonexistent/x.savedSearch")
    #expect(
      errorMessage { try SmartFolder(contentsOf: url) }
        == "cannot read /nonexistent/x.savedSearch")
  }
}
