import Foundation
import UniformTypeIdentifiers

/// One image file.
public struct Entry: Equatable {
  public let url: URL
  public let name: String
  public let modified: Date

  public init(url: URL, name: String, modified: Date) {
    self.url = url
    self.name = name
    self.modified = modified
  }
}

/// The kind of an Entry Source. `type` in the Settings File.
public enum EntrySourceType: String, Codable, CaseIterable {
  case directory, smartFolder, spotlightSearch
}

/// One place to collect Entries from. Entry Source Type picks the kind.
public enum EntrySource: Equatable {
  /// A folder (its path, `~` allowed). With recursive, the folders under it too.
  case directory(path: String, recursive: Bool)
  /// A Finder smart folder (the .savedSearch path, `~` allowed).
  case smartFolder(path: String)
  /// A Spotlight Search written in place (the query, and the scopes: folder paths with `~` allowed, or constant names).
  case spotlightSearch(query: String, scopes: [String])
}

extension EntrySource: Codable {
  private enum CodingKeys: String, CodingKey {
    case type, path, recursive, query, scopes
  }

  /// Branches on `type`. `recursive` is required only for directory. `scopes` must not be empty.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(EntrySourceType.self, forKey: .type) {
    case .directory:
      self = .directory(
        path: try container.decode(String.self, forKey: .path),
        recursive: try container.decode(Bool.self, forKey: .recursive))
    case .smartFolder:
      self = .smartFolder(path: try container.decode(String.self, forKey: .path))
    case .spotlightSearch:
      let scopes = try container.decode([String].self, forKey: .scopes)
      // An empty [String] decodes fine, so check it here
      if scopes.isEmpty {
        throw DecodingError.dataCorruptedError(
          forKey: .scopes, in: container, debugDescription: "empty")
      }
      self = .spotlightSearch(
        query: try container.decode(String.self, forKey: .query), scopes: scopes)
    }
  }

  /// `type` first, then `path` and `recursive` (directory only), or `query` and `scopes`, as one would write it.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .directory(let path, let recursive):
      try container.encode(EntrySourceType.directory, forKey: .type)
      try container.encode(path, forKey: .path)
      try container.encode(recursive, forKey: .recursive)
    case .smartFolder(let path):
      try container.encode(EntrySourceType.smartFolder, forKey: .type)
      try container.encode(path, forKey: .path)
    case .spotlightSearch(let query, let scopes):
      try container.encode(EntrySourceType.spotlightSearch, forKey: .type)
      try container.encode(query, forKey: .query)
      try container.encode(scopes, forKey: .scopes)
    }
  }
}

extension SpotlightSearch {
  /// From the scopes as written in the Settings File: a leading `~` is expanded, and constant names such as
  /// kMDQueryScopeHome are left as they are (URL(expandingTilde:) would turn them into paths under the current folder).
  public init(query: String, scopesAsWritten scopes: [String]) {
    self.init(query: query, scopes: scopes.map { ($0 as NSString).expandingTildeInPath })
  }
}

/// Order of the list.
public enum SortOrder: String, Codable, CaseIterable {
  case newest, oldest, name, nameDescending
}

extension Entry {
  /// Collects image files from an Entry Source. Unordered (use arranged(by:)).
  /// Empty when the folder is missing, the smart folder cannot be read, or the query is malformed.
  public static func load(from source: EntrySource) -> [Entry] {
    let keys: [URLResourceKey] = [
      .contentModificationDateKey, .contentTypeKey, .isRegularFileKey,
    ]
    let urls: [URL] =
      switch source {
      case .directory(let path, let recursive):
        contents(of: URL(expandingTilde: path), recursive: recursive, keys: keys)
      case .smartFolder(let path):
        (try? SmartFolder(contentsOf: URL(expandingTilde: path)))?.search.matchingURLs()
          ?? []
      case .spotlightSearch(let query, let scopes):
        SpotlightSearch(query: query, scopesAsWritten: scopes).matchingURLs()
      }

    return urls.compactMap { url -> Entry? in
      guard let values = try? url.resourceValues(forKeys: Set(keys)),
        values.isRegularFile == true,
        values.contentType?.conforms(to: .image) == true
      else { return nil }
      return Entry(
        url: url,
        name: url.lastPathComponent,
        modified: values.contentModificationDate ?? .distantPast)
    }
  }

  /// Collects from all Entry Sources and merges them. Keeps the written order; of duplicate files,
  /// only the first occurrence stays (overlapping folders, or a smart folder result overlapping a
  /// folder, must not list the same file twice).
  public static func load(from sources: [EntrySource]) -> [Entry] {
    var seen = Set<URL>()
    return sources.flatMap { load(from: $0) }.filter {
      seen.insert($0.url.standardizedFileURL).inserted
    }
  }

  /// Files in a folder. Hidden files are skipped. Empty when the folder is missing.
  private static func contents(of directory: URL, recursive: Bool, keys: [URLResourceKey])
    -> [URL]
  {
    let fm = FileManager.default
    if recursive {
      guard
        let enumerator = fm.enumerator(
          at: directory,
          includingPropertiesForKeys: keys,
          options: [.skipsHiddenFiles])
      else { return [] }
      return enumerator.compactMap { $0 as? URL }
    }
    return
      (try? fm.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: keys,
        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
      )) ?? []
  }
}

extension [Entry] {
  /// Sorts in the given order.
  public func arranged(by sortOrder: SortOrder) -> [Entry] {
    switch sortOrder {
    case .newest: sorted { $0.modified > $1.modified }
    case .oldest: sorted { $0.modified < $1.modified }
    case .name: sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    case .nameDescending:
      sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
    }
  }

  /// Keeps only the Entries whose file name contains filterText.
  /// - Leading and trailing whitespace is ignored.
  /// - Case-sensitive.
  public func filtered(byName filterText: String) -> [Entry] {
    let filterText = filterText.trimmingCharacters(in: .whitespaces)
    return filterText.isEmpty ? self : filter { $0.name.contains(filterText) }
  }
}
