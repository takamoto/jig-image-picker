// Shared test helpers.
import Foundation
import Testing

@testable import JigImagePickerCore

/// A scratch folder. TMPDIR when set (for sandboxes that cannot write to /var/folders).
func scratchDirectory() -> URL {
  if let path = ProcessInfo.processInfo.environment["TMPDIR"], !path.isEmpty {
    return URL(fileURLWithPath: path, isDirectory: true)
  }
  return FileManager.default.temporaryDirectory
}

/// The message of the thrown error. nil when nothing is thrown.
func errorMessage(_ body: () throws -> some Any) -> String? {
  do {
    _ = try body()
    return nil
  } catch {
    return "\(error)"
  }
}

/// Settings for tests. Every item is required, so there is one defaults block and tests overlay
/// their differences with <<: *defaults. entrySources is a list and cannot be overlaid; a test that
/// changes it writes the whole element.
let defaultsYAML = """
  defaults: &defaults
    entrySources:
      - type: directory
        path: /pics
        recursive: false
    sortOrder: newest
    itemLayout: &itemLayout
      thumbnailSize: 200
      thumbnailContentMode: fit
      showItemInfo: true
    dateFormat: &dateFormat
      format: "yyyy/MM/dd HH:mm:ss"
      locale: ja_JP
    window: &window { width: 960, height: 640 }
    clipboardContentType: image
    keyBindings: &keyBindings
      return: copy
      enter: copy
      escape: cancel
      cmd+y: quickLook
      cmd+delete: trash
      left: previous
      right: next
      up: previousRow
      ctrl+p: previousRow
      down: nextRow
      ctrl+n: nextRow

  """

/// Builds one profile: defaults overlaid with patch (a YAML fragment, one item per line).
func testProfile(_ patch: String = "") throws -> Profile {
  let body = patch.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n")
  let yaml =
    defaultsYAML + "defaultProfile: test\nprofiles:\n  test:\n    <<: *defaults\n" + body + "\n"
  return try #require(SettingsFile(yaml: yaml).profiles["test"])
}
