import Foundation

/// How the thumbnail is placed in the cell.
/// - fit:  The longer side matches the cell. The whole image shows, but an image with a different
///         aspect ratio leaves margins above/below or left/right.
/// - fill: The shorter side stretches to the cell. No margins and the grid stays even, but the
///         longer side is cropped, keeping the middle.
public enum ThumbnailContentMode: String, Codable, CaseIterable {
  case fit, fill

  /// The rectangle to draw the thumbnail in.
  /// fit matches the longer side to the box (never upscales). fill matches the shorter side,
  /// so it always fills the box. Both are centered. nil when the image size is 0.
  public func frame(for imageSize: CGSize, in box: CGRect) -> CGRect? {
    guard imageSize.width > 0, imageSize.height > 0 else { return nil }
    let horizontal = box.width / imageSize.width
    let vertical = box.height / imageSize.height
    let scale = self == .fill ? max(horizontal, vertical) : min(horizontal, vertical, 1)
    let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    return CGRect(
      x: box.midX - size.width / 2, y: box.midY - size.height / 2,
      width: size.width, height: size.height)
  }
}

public struct ItemLayout: Codable {
  public var thumbnailSize: CGFloat
  public var thumbnailContentMode: ThumbnailContentMode
  public var showItemInfo: Bool

  public static let padding: CGFloat = 6
  public static let spacing: CGFloat = 10
  public static let sectionInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

  /// Multiplier for the size requested from the thumbnail generator when using fill.
  /// QLThumbnailGenerator produces an image that "fits" the given box, so with a box of one
  /// side the longer side becomes that length and the shorter side ends up smaller. Stretching
  /// that would blur, so ask for a box this many times larger to get the shorter side up to the
  /// full length (2 covers aspect ratios up to 2:1 at 1x or better).
  private static let fillOversample: CGFloat = 2

  private enum CodingKeys: String, CodingKey {
    case thumbnailSize, thumbnailContentMode, showItemInfo
  }

  public init(
    thumbnailSize: CGFloat, thumbnailContentMode: ThumbnailContentMode, showItemInfo: Bool
  ) {
    self.thumbnailSize = thumbnailSize
    self.thumbnailContentMode = thumbnailContentMode
    self.showItemInfo = showItemInfo
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(pixels: thumbnailSize, forKey: .thumbnailSize)
    try container.encode(thumbnailContentMode, forKey: .thumbnailContentMode)
    try container.encode(showItemInfo, forKey: .showItemInfo)
  }

  /// Two lines: file name and date. 0 when hidden.
  public var infoHeight: CGFloat { showItemInfo ? 30 : 0 }

  public var itemSize: NSSize {
    NSSize(
      width: thumbnailSize + Self.padding * 2,
      height: thumbnailSize + infoHeight + Self.padding * 2)
  }

  /// Margin kept when scrolling the selected cell into view: one row, so it does not stick to
  /// the top or bottom edge.
  public var scrollMargin: CGFloat { Self.spacing + Self.sectionInsets.top }

  /// The side length requested from the thumbnail generator. fill stretches the shorter side to
  /// the cell, so it asks for that much more.
  public var requestedThumbnailSize: CGFloat {
    thumbnailContentMode == .fill ? thumbnailSize * Self.fillOversample : thumbnailSize
  }

  /// Cells per row. Used as the step for moving up and down.
  public func columns(forContentWidth width: CGFloat) -> Int {
    let usable = width - Self.sectionInsets.left - Self.sectionInsets.right
    return max(1, Int((usable + Self.spacing) / (itemSize.width + Self.spacing)))
  }
}
