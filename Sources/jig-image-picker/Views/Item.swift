import AppKit
import JigImagePickerCore

final class Item: NSCollectionViewItem {
  static let identifier = NSUserInterfaceItemIdentifier("Item")

  /// URL of the Entry being shown. Used to keep a late thumbnail out of a reused cell.
  private(set) var url: URL?
  private let thumbnail = ThumbnailView()
  private let info = ItemInfoView()
  private var built = false

  override func loadView() {
    let container = NSView()
    container.wantsLayer = true
    container.layer?.cornerRadius = 6
    view = container
  }

  /// Places the subviews. Cells are reused, so only the first time.
  func build(layout: ItemLayout) {
    guard !built else { return }
    built = true
    let padding = ItemLayout.padding
    thumbnail.contentMode = layout.thumbnailContentMode
    thumbnail.translatesAutoresizingMaskIntoConstraints = false
    info.translatesAutoresizingMaskIntoConstraints = false
    info.isHidden = !layout.showItemInfo
    view.addSubview(thumbnail)
    view.addSubview(info)
    NSLayoutConstraint.activate([
      thumbnail.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
      thumbnail.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
      thumbnail.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
      thumbnail.heightAnchor.constraint(equalToConstant: layout.thumbnailSize),
      info.topAnchor.constraint(equalTo: thumbnail.bottomAnchor, constant: 2),
      info.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
      info.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),
    ])
  }

  /// Shows an Entry. thumbnail is nil when not cached; set thumbnailImage when it arrives.
  func show(_ entry: Entry, date: String, thumbnail image: NSImage?) {
    url = entry.url
    info.name = entry.name
    info.date = date
    view.toolTip = entry.name  // The full name is available in the tooltip in case it is truncated
    thumbnail.image = image
  }

  var thumbnailImage: NSImage? {
    get { thumbnail.image }
    set { thumbnail.image = newValue }
  }

  override var isSelected: Bool {
    didSet {
      view.layer?.backgroundColor =
        isSelected
        ? NSColor.selectedContentBackgroundColor.cgColor
        : NSColor.clear.cgColor
      info.isSelected = isSelected
    }
  }
}
