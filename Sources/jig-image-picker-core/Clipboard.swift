import AppKit
import UniformTypeIdentifiers

/// What copy puts on the clipboard.
/// - image: The image data itself. Pastes directly into Slack and the like (not as an attachment).
///          The data keeps the file's format, so a target that reads only PNG may not accept
///          JPEG or HEIC (use file in that case).
/// - file:  A file reference. Same as ⌘C in Finder; pasting gives a "file".
/// - path:  The path as a string. For pasting into a terminal or an editor.
public enum ClipboardContentType: String, Codable, CaseIterable {
  case image, file, path
}

/// Writing to the clipboard.
public enum Clipboard {
  /// Copies an image file to the clipboard.
  /// - On failure, returns the error message to show in the status line.
  /// - contentType picks what to put there (image data, file reference, path string).
  public static func copy(
    _ entry: Entry, as contentType: ClipboardContentType, to clipboard: NSPasteboard
  ) -> String? {
    clipboard.clearContents()
    let stored: Bool
    switch contentType {
    case .image:
      guard let (data, type) = imageData(for: entry.url) else {
        return "could not read the image"
      }
      stored = clipboard.setData(data, forType: type)
    case .file:
      stored = clipboard.writeObjects([entry.url as NSURL])
    case .path:
      stored = clipboard.setString(entry.url.path, forType: .string)
    }
    return stored ? nil : "could not write to the clipboard"
  }

  /// Reads the image file and infers the pasteboard type for it.
  private static func imageData(for url: URL) -> (Data, NSPasteboard.PasteboardType)? {
    // The extension is a fallback for when resourceValues returns no type
    let type =
      (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType)
      ?? UTType(filenameExtension: url.pathExtension)
    guard let identifier = type?.identifier,
      let data = try? Data(contentsOf: url)
    else { return nil }
    return (data, NSPasteboard.PasteboardType(identifier))
  }
}
