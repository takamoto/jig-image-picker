import AppKit

final class PickerCollectionView: NSCollectionView {
  /// Called on a double-click on an item. The first click has already selected it.
  var onDoubleClickItem: (() -> Void)?

  override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)
    guard event.clickCount == 2,
      indexPathForItem(at: convert(event.locationInWindow, from: nil)) != nil
    else { return }
    onDoubleClickItem?()
  }
}
