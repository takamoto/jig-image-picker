import AppKit
import JigImagePickerCore
import Quartz

/// PickerController wires up the delegate and dataSource.
final class PickerContentView: NSVisualEffectView {
  let filterField = NSTextField()
  /// Shows the item count, or the reason for a failure.
  let messageLabel = NSTextField(labelWithString: "")
  let collectionView = PickerCollectionView()
  let scrollView = NSScrollView()
  /// The Quick Look panel looks for its controller in the key window's responder chain, so accept it here and hand it over.
  weak var quickLook: QuickLookController?

  init(layout: ItemLayout) {
    super.init(frame: .zero)
    material = .sidebar
    blendingMode = .behindWindow
    state = .active
    wantsLayer = true
    layer?.cornerRadius = 12
    layer?.masksToBounds = true
    build(layout: layout)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  private func build(layout: ItemLayout) {
    // With no title bar, this row is the face of the window: no border and a larger font.
    // A plain NSTextField rather than NSSearchField, because without a border the search
    // button gets no room and the magnifier overlaps the placeholder. We place the magnifier ourselves.
    let filterIcon = NSImageView()
    filterIcon.translatesAutoresizingMaskIntoConstraints = false
    filterIcon.image = NSImage(
      systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
    filterIcon.contentTintColor = .secondaryLabelColor
    filterIcon.symbolConfiguration = .init(pointSize: 14, weight: .regular)
    addSubview(filterIcon)

    filterField.translatesAutoresizingMaskIntoConstraints = false
    filterField.placeholderString = "Filter"
    filterField.focusRingType = .none
    filterField.isBezeled = false
    filterField.isBordered = false
    filterField.drawsBackground = false
    filterField.font = .systemFont(ofSize: 16)
    filterField.lineBreakMode = .byTruncatingTail
    filterField.cell?.usesSingleLineMode = true
    addSubview(filterField)

    // Divider between the filter and the list
    let separator = NSBox()
    separator.boxType = .separator
    separator.translatesAutoresizingMaskIntoConstraints = false
    addSubview(separator)

    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.font = .systemFont(ofSize: 11)
    messageLabel.textColor = .secondaryLabelColor
    messageLabel.alignment = .right
    messageLabel.lineBreakMode = .byTruncatingTail
    addSubview(messageLabel)

    let flow = NSCollectionViewFlowLayout()
    flow.itemSize = layout.itemSize
    flow.minimumInteritemSpacing = ItemLayout.spacing
    flow.minimumLineSpacing = ItemLayout.spacing
    flow.sectionInset = ItemLayout.sectionInsets

    collectionView.collectionViewLayout = flow
    collectionView.isSelectable = true
    collectionView.allowsMultipleSelection = false
    collectionView.backgroundColors = [.clear]
    collectionView.register(Item.self, forItemWithIdentifier: Item.identifier)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.documentView = collectionView
    scrollView.hasVerticalScroller = true
    scrollView.drawsBackground = false
    addSubview(scrollView)

    NSLayoutConstraint.activate([
      filterIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
      filterIcon.centerYAnchor.constraint(equalTo: filterField.centerYAnchor),
      filterField.topAnchor.constraint(equalTo: topAnchor, constant: 14),
      filterField.leadingAnchor.constraint(equalTo: filterIcon.trailingAnchor, constant: 8),
      messageLabel.leadingAnchor.constraint(
        equalTo: filterField.trailingAnchor, constant: 12),
      messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
      messageLabel.centerYAnchor.constraint(equalTo: filterField.centerYAnchor),
      messageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
      separator.topAnchor.constraint(equalTo: filterField.bottomAnchor, constant: 12),
      separator.leadingAnchor.constraint(equalTo: leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: separator.bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool { true }

  override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
    panel.dataSource = quickLook
    panel.delegate = quickLook
    quickLook?.sync()
  }

  override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
    panel.dataSource = nil
    panel.delegate = nil
    quickLook?.panelDidClose()
  }
}
