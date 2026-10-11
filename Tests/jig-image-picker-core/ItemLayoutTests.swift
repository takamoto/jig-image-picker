import Foundation
import Testing

@testable import JigImagePickerCore

@Suite struct Layout {
  @Test func itemSizeIncludesInfo() {
    let layout = ItemLayout(thumbnailSize: 200, thumbnailContentMode: .fit, showItemInfo: true)
    #expect(layout.itemSize == NSSize(width: 212, height: 242))
    #expect(layout.infoHeight == 30)
  }

  @Test func itemSizeWithoutInfo() {
    let layout = ItemLayout(thumbnailSize: 200, thumbnailContentMode: .fit, showItemInfo: false)
    #expect(layout.itemSize == NSSize(width: 212, height: 212))
  }

  @Test func columnsFromContentWidth() {
    let layout = ItemLayout(thumbnailSize: 200, thumbnailContentMode: .fit, showItemInfo: true)
    // 4 cells of 212 + 10 spacing fit in the usable width of 936
    #expect(layout.columns(forContentWidth: 960) == 4)
    #expect(layout.columns(forContentWidth: 100) == 1)
    #expect(layout.columns(forContentWidth: 0) == 1)
  }

  @Test func requestedSizeIsOversampledForFill() {
    #expect(
      ItemLayout(thumbnailSize: 200, thumbnailContentMode: .fit, showItemInfo: true)
        .requestedThumbnailSize == 200)
    #expect(
      ItemLayout(thumbnailSize: 200, thumbnailContentMode: .fill, showItemInfo: true)
        .requestedThumbnailSize == 400)
  }

  @Test func fromSettings() throws {
    let layout = try testProfile(
      "itemLayout: { thumbnailSize: 120, thumbnailContentMode: fill, showItemInfo: false }"
    ).itemLayout
    #expect(
      layout.thumbnailSize == 120 && layout.thumbnailContentMode == .fill
        && !layout.showItemInfo)
  }
}

@Suite struct ThumbnailFrames {
  let box = CGRect(x: 0, y: 0, width: 200, height: 200)

  @Test func fitShrinksTheLongSideToTheBox() {
    let frame = ThumbnailContentMode.fit.frame(for: CGSize(width: 400, height: 200), in: box)
    #expect(frame == CGRect(x: 0, y: 50, width: 200, height: 100))
  }

  @Test func fitNeverEnlarges() {
    let frame = ThumbnailContentMode.fit.frame(for: CGSize(width: 100, height: 50), in: box)
    #expect(frame == CGRect(x: 50, y: 75, width: 100, height: 50))
  }

  @Test func fillCoversTheBoxAndOverflowsTheLongSide() {
    let frame = ThumbnailContentMode.fill.frame(for: CGSize(width: 400, height: 200), in: box)
    #expect(frame == CGRect(x: -100, y: 0, width: 400, height: 200))
  }

  @Test func fillEnlargesSmallImages() {
    let frame = ThumbnailContentMode.fill.frame(for: CGSize(width: 50, height: 100), in: box)
    #expect(frame == CGRect(x: 0, y: -100, width: 200, height: 400))
  }

  @Test func degenerateImageYieldsNothing() {
    #expect(ThumbnailContentMode.fit.frame(for: .zero, in: box) == nil)
  }
}
