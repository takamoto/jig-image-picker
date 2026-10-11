import CoreServices
import Foundation

/// A Finder smart folder (.savedSearch): a saved Spotlight Search.
public struct SmartFolder: Equatable {
  /// The Spotlight Search read from the file.
  public var search: SpotlightSearch

  /// Builds from the plist of a .savedSearch.
  /// - The query is RawQueryDict.RawQuery (else the top-level RawQuery).
  /// - The scopes are RawQueryDict.SearchScopes (else SearchCriteria.FXScopeArrayOfPaths, else the whole Mac).
  /// - UserFilesOnly (an undocumented Finder option) is approximated by excluding system support files.
  ///   FinderFilesOnly is ignored.
  public init(plist data: Data) throws {
    guard
      let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: Any]
    else {
      throw SmartFolderError("not a valid plist")
    }
    let rawQueryDict = plist["RawQueryDict"] as? [String: Any] ?? [:]
    let searchCriteria = plist["SearchCriteria"] as? [String: Any] ?? [:]
    guard let rawQuery = (rawQueryDict["RawQuery"] ?? plist["RawQuery"]) as? String else {
      throw SmartFolderError("missing RawQuery")
    }
    let query =
      rawQueryDict["UserFilesOnly"] as? Bool == true
      ? "(\(rawQuery)) && (kMDItemSupportFileType != \"MDSystemFile\")"
      : rawQuery
    let scopes =
      (rawQueryDict["SearchScopes"] ?? searchCriteria["FXScopeArrayOfPaths"]) as? [String]
      ?? []
    search = SpotlightSearch(
      query: query, scopes: scopes.isEmpty ? [kMDQueryScopeComputer as String] : scopes)
  }

  /// Reads and builds from a .savedSearch. An unreadable file gives a message with the path;
  /// bad contents give one prefixed with the file name.
  public init(contentsOf url: URL) throws {
    guard let data = try? Data(contentsOf: url) else {
      throw SmartFolderError("cannot read \(url.path)")
    }
    do {
      try self.init(plist: data)
    } catch let error as SmartFolderError {
      throw SmartFolderError("\(url.lastPathComponent): \(error.description)")
    }
  }
}

public struct SmartFolderError: Error, CustomStringConvertible {
  public let description: String

  init(_ description: String) {
    self.description = description
  }
}
