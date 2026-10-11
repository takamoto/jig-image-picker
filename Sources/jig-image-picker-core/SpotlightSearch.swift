import CoreServices
import Foundation

/// A Spotlight search: the query and the search scopes.
public struct SpotlightSearch: Equatable {
  /// The query handed to Spotlight (an MDQuery string).
  public var query: String
  /// Where to search: folder paths, or constant names such as kMDQueryScopeComputer.
  public var scopes: [String]

  public init(query: String, scopes: [String]) {
    self.query = query
    self.scopes = scopes
  }

  /// Whether Spotlight accepts the query. False when it is empty or malformed.
  public var isQueryValid: Bool {
    makeQuery() != nil
  }

  /// Runs the Spotlight search and returns the matching file URLs. Synchronous.
  /// Empty when the query cannot be created or executed.
  public func matchingURLs() -> [URL] {
    guard let mdQuery = makeQuery() else { return [] }
    MDQuerySetSearchScope(mdQuery, scopes as CFArray, 0)
    guard MDQueryExecute(mdQuery, CFOptionFlags(kMDQuerySynchronous.rawValue)) else {
      return []
    }
    return (0..<MDQueryGetResultCount(mdQuery)).compactMap { index in
      guard let pointer = MDQueryGetResultAtIndex(mdQuery, index) else { return nil }
      let item = Unmanaged<MDItem>.fromOpaque(pointer).takeUnretainedValue()
      guard let path = MDItemCopyAttribute(item, kMDItemPath) as? String else { return nil }
      return URL(fileURLWithPath: path)
    }
  }

  /// nil when the query is empty or malformed (MDQueryCreate returns NULL).
  private func makeQuery() -> MDQuery? {
    MDQueryCreate(kCFAllocatorDefault, query as CFString, nil, nil)
  }
}
