import Foundation
import Yams

public struct WindowSize: Codable, Equatable {
  public var width: CGFloat
  public var height: CGFloat

  private enum CodingKeys: String, CodingKey {
    case width, height
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(pixels: width, forKey: .width)
    try container.encode(pixels: height, forKey: .height)
  }
}

/// The items of one profile. These are the settings the app uses.
public struct Profile: Codable {
  public var entrySources: [EntrySource]
  public var sortOrder: SortOrder
  public var itemLayout: ItemLayout
  public var dateFormat: DateFormat
  public var window: WindowSize
  public var clipboardContentType: ClipboardContentType
  public var keyBindings: KeyBindings

  private enum CodingKeys: String, CodingKey {
    case entrySources, sortOrder, itemLayout, dateFormat, window, clipboardContentType,
      keyBindings
  }

  /// Same keys and nesting as the Settings File. Key Bindings are written as Key Name -> Action,
  /// sorted by Key Name (a dictionary would come out in hash order).
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(entrySources, forKey: .entrySources)
    try container.encode(sortOrder, forKey: .sortOrder)
    try container.encode(itemLayout, forKey: .itemLayout)
    try container.encode(dateFormat, forKey: .dateFormat)
    try container.encode(window, forKey: .window)
    try container.encode(clipboardContentType, forKey: .clipboardContentType)
    var bindings = container.nestedContainer(keyedBy: KeyNameKey.self, forKey: .keyBindings)
    for (chord, action) in keyBindings.sorted(by: { $0.key.keyName < $1.key.keyName }) {
      try bindings.encode(action, forKey: KeyNameKey(stringValue: chord.keyName))
    }
  }
}

extension Profile: CustomStringConvertible {
  /// The profile dumped as YAML, in the shape of the Settings File. Shown by --check.
  public var description: String {
    do {
      return try YAMLEncoder().encode(self).trimmingCharacters(in: .newlines)
    } catch {
      return "\(error)"
    }
  }
}

extension KeyedEncodingContainer {
  /// Writes a size in px. A whole number comes out as an integer (`200`), because Yams
  /// writes a Double in scientific notation (`2.0e+2`).
  mutating func encode(pixels value: CGFloat, forKey key: Key) throws {
    if let whole = Int(exactly: value) {
      try encode(whole, forKey: key)
    } else {
      try encode(value, forKey: key)
    }
  }
}
