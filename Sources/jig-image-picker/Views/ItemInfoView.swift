import AppKit

final class ItemInfoView: NSView {
  private let nameLabel = NSTextField(labelWithString: "")
  private let dateLabel = NSTextField(labelWithString: "")

  var name: String {
    get { nameLabel.stringValue }
    set { nameLabel.stringValue = newValue }
  }

  var date: String {
    get { dateLabel.stringValue }
    set { dateLabel.stringValue = newValue }
  }

  /// Inverted colors while selected.
  var isSelected = false {
    didSet {
      nameLabel.textColor = isSelected ? .alternateSelectedControlTextColor : .labelColor
      dateLabel.textColor =
        isSelected ? .alternateSelectedControlTextColor : .secondaryLabelColor
    }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.alignment = .center
    nameLabel.font = .systemFont(ofSize: 11)
    nameLabel.lineBreakMode = .byTruncatingMiddle  // Truncate file names in the middle
    dateLabel.translatesAutoresizingMaskIntoConstraints = false
    dateLabel.alignment = .center
    dateLabel.font = .systemFont(ofSize: 10)
    dateLabel.textColor = .secondaryLabelColor
    dateLabel.lineBreakMode = .byTruncatingMiddle
    addSubview(nameLabel)
    addSubview(dateLabel)
    NSLayoutConstraint.activate([
      nameLabel.topAnchor.constraint(equalTo: topAnchor),
      nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
      dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      dateLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
