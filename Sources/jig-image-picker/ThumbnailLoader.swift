import AppKit
import JigImagePickerCore
import QuickLookThumbnailing

/// QLThumbnailGenerator uses the system thumbnail cache, so the second showing is fast.
/// Thumbnails are generated lazily for the cells shown, and the results are also kept in-process.
final class ThumbnailLoader {
  private let requestedSize: CGFloat
  private var cache: [URL: NSImage] = [:]
  private var inflight: Set<URL> = []

  init(requestedSize: CGFloat) {
    self.requestedSize = requestedSize
  }

  func cached(_ url: URL) -> NSImage? { cache[url] }

  func load(_ url: URL, scale: CGFloat, completion: @escaping (URL, NSImage) -> Void) {
    guard cache[url] == nil, !inflight.contains(url) else { return }
    inflight.insert(url)
    let request = QLThumbnailGenerator.Request(
      fileAt: url,
      size: CGSize(width: requestedSize, height: requestedSize),
      scale: scale,
      representationTypes: .thumbnail
    )
    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
      DispatchQueue.main.async {
        self.inflight.remove(url)
        guard let image = representation?.nsImage else { return }
        self.cache[url] = image
        completion(url, image)
      }
    }
  }
}
