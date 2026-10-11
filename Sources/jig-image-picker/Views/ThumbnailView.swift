import AppKit
import JigImagePickerCore

final class ThumbnailView: NSView {
  var contentMode: ThumbnailContentMode = .fit
  var image: NSImage? {
    didSet { needsDisplay = true }
  }

  /// NSImageView.imageScaling has no fill mode (stretch the shorter side to the cell and crop
  /// the overflow of the longer side), so this draws by itself instead of using NSImageView.
  override func draw(_ dirtyRect: NSRect) {
    guard let image, let frame = contentMode.frame(for: image.size, in: bounds) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(rect: bounds).setClip()
    image.draw(in: frame)
    NSGraphicsContext.restoreGraphicsState()
  }
}
