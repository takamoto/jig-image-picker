import AppKit
import JigImagePickerCore
import Quartz

final class QuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
  /// True only while the panel is open. The picker exits when focus leaves, except while this is true.
  private(set) var isVisible = false
  /// The images currently listed and the selection. The picker swaps them, so fetch each time.
  var entries: () -> [Entry] = { [] }
  var selectedIndex: () -> Int? = { nil }
  /// Gives key status back to the picker after closing.
  var didClose: () -> Void = {}

  /// `isVisible` must be set before the panel actually appears,
  /// because the picker's didResignKey fires as soon as makeKeyAndOrderFront is called.
  func toggle() {
    guard !entries().isEmpty, let panel = QLPreviewPanel.shared() else { return }
    if isVisible {
      panel.orderOut(nil)
      isVisible = false
      didClose()
    } else {
      isVisible = true
      panel.makeKeyAndOrderFront(nil)
    }
  }

  /// Also called when Quick Look closes itself (Esc or Space).
  func panelDidClose() {
    isVisible = false
    didClose()
  }

  func sync() {
    guard isVisible, let panel = QLPreviewPanel.shared() else { return }
    panel.reloadData()
    panel.currentPreviewItemIndex = selectedIndex() ?? 0
  }

  func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { entries().count }

  func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
    let entries = entries()
    return entries.indices.contains(index) ? entries[index].url as NSURL : nil
  }

  /// Keys are handled by the local event monitor, so nothing to do here.
  func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool { false }
}
