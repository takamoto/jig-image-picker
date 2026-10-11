import AppKit
import Testing

@testable import JigImagePickerCore

@Suite struct Copying {
  /// Puts a 1×1 PNG in the scratch folder.
  private func makePNG() throws -> Entry {
    let url = scratchDirectory().appendingPathComponent("image-picker-\(UUID()).png")
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1, bitsPerSample: 8,
      samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    try bitmap.representation(using: .png, properties: [:])!.write(to: url)
    return Entry(url: url, name: url.lastPathComponent, modified: Date())
  }

  /// Tests run in parallel, so use a named NSPasteboard per test instead of the shared general one.
  private func makeClipboard() -> NSPasteboard {
    NSPasteboard(name: NSPasteboard.Name("image-picker-test-\(UUID())"))
  }

  @Test func imagePutsFileBytesUnderItsOwnType() throws {
    let entry = try makePNG()
    defer { try? FileManager.default.removeItem(at: entry.url) }
    let bytes = try Data(contentsOf: entry.url)
    let clipboard = makeClipboard()
    #expect(Clipboard.copy(entry, as: .image, to: clipboard) == nil)
    #expect(clipboard.data(forType: .png) == bytes)
  }

  @Test func fileWritesURL() throws {
    let entry = try makePNG()
    defer { try? FileManager.default.removeItem(at: entry.url) }
    let clipboard = makeClipboard()
    #expect(Clipboard.copy(entry, as: .file, to: clipboard) == nil)
    let urls = (clipboard.readObjects(forClasses: [NSURL.self]) ?? []).compactMap { $0 as? URL }
    #expect(urls.map(\.standardizedFileURL) == [entry.url.standardizedFileURL])
  }

  @Test func pathWritesString() {
    let entry = Entry(url: URL(fileURLWithPath: "/pics/a.png"), name: "a.png", modified: Date())
    let clipboard = makeClipboard()
    #expect(Clipboard.copy(entry, as: .path, to: clipboard) == nil)
    #expect(clipboard.string(forType: .string) == "/pics/a.png")
  }

  @Test func unreadableImageReportsFailure() {
    let entry = Entry(
      url: URL(fileURLWithPath: "/nonexistent/\(UUID()).png"), name: "x.png", modified: Date()
    )
    #expect(
      Clipboard.copy(entry, as: .image, to: makeClipboard()) == "could not read the image")
  }
}
