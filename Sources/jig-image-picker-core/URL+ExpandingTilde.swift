import Foundation

extension URL {
  /// File URL of a path written in the Settings File, with a leading `~` expanded to the home folder.
  public init(expandingTilde path: String) {
    self.init(fileURLWithPath: (path as NSString).expandingTildeInPath)
  }
}
