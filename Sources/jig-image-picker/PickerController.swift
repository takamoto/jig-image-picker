import AppKit
import JigImagePickerCore

final class PickerController: NSObject, NSApplicationDelegate, NSCollectionViewDataSource,
  NSCollectionViewDelegate, NSTextFieldDelegate
{
  private let profile: Profile
  private let layout: ItemLayout
  private let loader: ThumbnailLoader
  private let dateFormatter: DateFormatter
  private let quickLook = QuickLookController()

  private var allEntries: [Entry] = []
  private var entries: [Entry] = []

  private var window: NSWindow!
  private var contentView: PickerContentView!
  private var collectionView: PickerCollectionView { contentView.collectionView }
  private var filterField: NSTextField { contentView.filterField }
  private var messageLabel: NSTextField { contentView.messageLabel }

  init(profile: Profile) {
    self.profile = profile
    layout = profile.itemLayout
    loader = ThumbnailLoader(requestedSize: layout.requestedThumbnailSize)
    dateFormatter = profile.dateFormat.formatter
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    allEntries = Entry.load(from: profile.entrySources).arranged(by: profile.sortOrder)
    entries = allEntries
    buildWindow()
    showEntryCount()
    selectIndex(0)

    // See keyDown before the window does, so the filter field does not eat arrows and Enter.
    // This monitor receives every keyDown in the app regardless of the key window, so it also
    // fires while Quick Look is showing. KeyBindings.action(for:quickLookVisible:) sorts that out.
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self else { return event }
      // While the IME is composing, it takes precedence over the bindings (Esc cancels, Enter commits)
      if let editor = self.window.firstResponder as? NSTextView, editor.hasMarkedText() {
        return event
      }
      guard
        let action = self.profile.keyBindings.action(
          for: KeyChord(event: event),
          quickLookVisible: self.quickLook.isVisible)
      else { return event }
      self.perform(action)
      return nil
    }

    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(filterField)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

  // MARK: Window

  private func buildWindow() {
    window = PickerWindow(
      contentRect: NSRect(
        x: 0, y: 0, width: profile.window.width, height: profile.window.height),
      styleMask: [.borderless, .resizable],
      backing: .buffered,
      defer: false
    )
    window.isReleasedWhenClosed = false
    window.level = .floating
    // Make the window itself transparent and let the content view draw, so the rounded corners show
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    // There is no title bar, so allow dragging by the background
    window.isMovableByWindowBackground = true
    window.center()

    contentView = PickerContentView(layout: layout)
    contentView.quickLook = quickLook
    contentView.filterField.delegate = self
    contentView.collectionView.dataSource = self
    contentView.collectionView.delegate = self
    contentView.collectionView.onDoubleClickItem = { [weak self] in self?.perform(.copy) }
    window.contentView = contentView

    quickLook.entries = { [weak self] in self?.entries ?? [] }
    quickLook.selectedIndex = { [weak self] in self?.selectedIndex }
    quickLook.didClose = { [weak self] in
      guard let self else { return }
      self.window.makeKeyAndOrderFront(nil)
      self.window.makeFirstResponder(self.filterField)
    }

    // Close when focus leaves (this picker is opened from a launcher or hotkey; it should not linger).
    // Opening Quick Look takes key status away from us, so stay open only then.
    NotificationCenter.default.addObserver(
      forName: NSWindow.didResignKeyNotification, object: window, queue: .main
    ) { [weak self] _ in
      guard self?.quickLook.isVisible != true else { return }
      NSApp.terminate(nil)
    }
  }

  private func showEntryCount() {
    messageLabel.stringValue = "\(entries.count) items"
    messageLabel.textColor = .secondaryLabelColor
  }

  private func showFailureNotice(_ reason: String) {
    messageLabel.stringValue = reason
    messageLabel.textColor = .systemRed
  }

  // MARK: Data source

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int)
    -> Int
  {
    entries.count
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    itemForRepresentedObjectAt indexPath: IndexPath
  ) -> NSCollectionViewItem {
    let item = collectionView.makeItem(withIdentifier: Item.identifier, for: indexPath)
    guard let cell = item as? Item else { return item }
    cell.build(layout: layout)
    let entry = entries[indexPath.item]
    let cached = loader.cached(entry.url)
    cell.show(entry, date: dateFormatter.string(from: entry.modified), thumbnail: cached)
    if cached == nil {
      loader.load(entry.url, scale: window.backingScaleFactor) {
        [weak collectionView] url, image in
        // The cell may have been reused by the time this returns, so set it only when the URL matches
        guard let cell = collectionView?.item(at: indexPath) as? Item, cell.url == url
        else { return }
        cell.thumbnailImage = image
      }
    }
    return cell
  }

  // MARK: Selection

  private var selectedIndex: Int? {
    collectionView.selectionIndexPaths.first?.item
  }

  private func selectedEntry() -> Entry? {
    guard let index = selectedIndex, entries.indices.contains(index) else { return nil }
    return entries[index]
  }

  private func selectIndex(_ index: Int) {
    guard !entries.isEmpty else {
      collectionView.deselectAll(nil)
      return
    }
    let clamped = min(max(index, 0), entries.count - 1)
    let path = IndexPath(item: clamped, section: 0)
    collectionView.selectionIndexPaths = [path]
    scrollToItem(at: path)
    quickLook.sync()
  }

  /// `NSCollectionView.scrollToItems(at:scrollPosition:)` sometimes does nothing after a selection change,
  /// so compute the cell's rectangle ourselves and use `scrollToVisible` (which moves the parent clip view).
  private func scrollToItem(at path: IndexPath) {
    guard let attributes = collectionView.layoutAttributesForItem(at: path) else { return }
    collectionView.scrollToVisible(attributes.frame.insetBy(dx: 0, dy: -layout.scrollMargin))
  }

  private var columns: Int {
    layout.columns(forContentWidth: contentView.scrollView.contentSize.width)
  }

  private func move(by offset: Int) {
    selectIndex((selectedIndex ?? 0) + offset)
  }

  /// Selection by click or drag. Key-driven selection is synced directly by selectIndex.
  func collectionView(
    _ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>
  ) {
    quickLook.sync()
  }

  // MARK: Key handling

  /// profile.keyBindings owns all the bindings. This is only what each action does.
  private func perform(_ action: Action) {
    switch action {
    case .cancel:  // Clear the filter if there is one, otherwise close
      if filterField.stringValue.isEmpty {
        NSApp.terminate(nil)
      } else {
        filterField.stringValue = ""
        applyFilter()
      }
    case .copy: copySelection()
    case .quickLook: quickLook.toggle()
    case .trash: trashSelection()
    case .previous: move(by: -1)
    case .next: move(by: 1)
    case .previousRow: move(by: -columns)
    case .nextRow: move(by: columns)
    }
  }

  // MARK: Filter

  func controlTextDidChange(_ notification: Notification) {
    applyFilter()
  }

  private func applyFilter() {
    entries = allEntries.filtered(byName: filterField.stringValue)
    collectionView.reloadData()
    showEntryCount()
    selectIndex(0)
  }

  // MARK: Actions

  /// Copies to the clipboard and exits.
  private func copySelection() {
    guard let entry = selectedEntry() else { return }
    if let failure = Clipboard.copy(entry, as: profile.clipboardContentType, to: .general) {
      showFailureNotice(failure)
      NSSound.beep()
      return
    }
    NSApp.terminate(nil)
  }

  private func trashSelection() {
    guard let index = selectedIndex, let entry = selectedEntry() else { return }
    NSWorkspace.shared.recycle([entry.url]) { [weak self] _, error in
      DispatchQueue.main.async {
        guard let self else { return }
        if error != nil {
          self.showFailureNotice("could not move to Trash")
          NSSound.beep()
          return
        }
        self.allEntries.removeAll { $0.url == entry.url }
        self.entries.remove(at: index)
        self.collectionView.reloadData()
        self.showEntryCount()
        self.selectIndex(index)
      }
    }
  }
}
