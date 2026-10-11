import AppKit

/// A pressed key combination.
public struct KeyChord: Hashable {
  /// The modifier keys we track.
  /// Arrow keys can also set .function and .numericPad, which is awkward to handle, so those are left out.
  private static let trackedModifiers: NSEvent.ModifierFlags = [
    .command, .control, .option, .shift,
  ]

  /// Modifier flags and their spellings. keyName uses the first spelling, in this order
  private static let modifierNames: [(flag: NSEvent.ModifierFlags, names: [String])] = [
    (.control, ["ctrl", "control", "⌃"]),
    (.option, ["opt", "option", "alt", "⌥"]),
    (.shift, ["shift", "⇧"]),
    (.command, ["cmd", "command", "⌘"]),
  ]

  /// Key spellings and virtual key codes. When a code has several spellings, keyName uses the first
  private static let keyNames: [(name: String, code: UInt16)] = [
    ("a", 0), ("s", 1), ("d", 2), ("f", 3), ("h", 4), ("g", 5), ("z", 6), ("x", 7), ("c", 8),
    ("v", 9),
    ("b", 11), ("q", 12), ("w", 13), ("e", 14), ("r", 15), ("y", 16), ("t", 17),
    ("1", 18), ("2", 19), ("3", 20), ("4", 21), ("6", 22), ("5", 23), ("9", 25), ("7", 26),
    ("8", 28), ("0", 29),
    ("equal", 24), ("plus", 24), ("minus", 27), ("rightbracket", 30), ("leftbracket", 33),
    ("o", 31), ("u", 32), ("i", 34), ("p", 35), ("l", 37), ("j", 38), ("k", 40),
    ("quote", 39), ("semicolon", 41), ("backslash", 42), ("comma", 43), ("slash", 44),
    ("n", 45), ("m", 46), ("period", 47), ("grave", 50),
    ("return", 36), ("enter", 76), ("keypadenter", 76),
    ("tab", 48), ("space", 49), ("delete", 51), ("backspace", 51), ("forwarddelete", 117),
    ("escape", 53), ("esc", 53),
    ("home", 115), ("end", 119), ("pageup", 116), ("pagedown", 121),
    ("left", 123), ("right", 124), ("down", 125), ("up", 126),
    ("f1", 122), ("f2", 120), ("f3", 99), ("f4", 118), ("f5", 96), ("f6", 97),
    ("f7", 98), ("f8", 100), ("f9", 101), ("f10", 109), ("f11", 103), ("f12", 111),
  ]

  private static let modifierFlags: [String: NSEvent.ModifierFlags] = Dictionary(
    uniqueKeysWithValues: modifierNames.flatMap { entry in entry.names.map { ($0, entry.flag) }
    })
  private static let keyCodes: [String: UInt16] = Dictionary(
    uniqueKeysWithValues: keyNames.map { ($0.name, $0.code) })
  private static let canonicalKeyNames: [UInt16: String] = Dictionary(
    keyNames.map { ($0.code, $0.name) }, uniquingKeysWith: { first, _ in first })

  public let keyCode: UInt16
  public let modifiers: UInt

  public init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
    self.keyCode = keyCode
    self.modifiers = modifiers.intersection(Self.trackedModifiers).rawValue
  }

  public init(event: NSEvent) {
    self.init(keyCode: event.keyCode, modifiers: event.modifierFlags)
  }

  /// Builds from a key name such as "cmd+y", "ctrl+n" or "return". nil when it cannot be parsed.
  public init?(keyName: String) {
    let parts = keyName.lowercased().split(separator: "+")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
    guard let name = parts.last, let code = Self.keyCodes[name] else { return nil }
    var modifiers: NSEvent.ModifierFlags = []
    for part in parts.dropLast() {
      guard let flag = Self.modifierFlags[part] else { return nil }
      modifiers.insert(flag)
    }
    self.init(keyCode: code, modifiers: modifiers)
  }

  /// The canonical key name. Modifiers come in the order ctrl, opt, shift, cmd. A key code not in the table stays numeric
  public var keyName: String {
    let flags = NSEvent.ModifierFlags(rawValue: modifiers)
    let parts = Self.modifierNames.filter { flags.contains($0.flag) }.map { $0.names[0] }
    return (parts + [Self.canonicalKeyNames[keyCode] ?? String(keyCode)]).joined(separator: "+")
  }
}

/// For reading [KeyChord: Action] from a YAML mapping. The mapping keys are read by init(codingKey:).
/// Decodable is only a formality required of dictionary keys; it reads a key name written in value position.
extension KeyChord: Decodable, CodingKeyRepresentable {
  public init(from decoder: Decoder) throws {
    let name = try decoder.singleValueContainer().decode(String.self)
    guard let chord = KeyChord(keyName: name) else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "unknown key: \(name)"))
    }
    self = chord
  }

  public init?<T: CodingKey>(codingKey: T) {
    self.init(keyName: codingKey.stringValue)
  }

  public var codingKey: CodingKey { KeyNameKey(stringValue: keyName) }
}

/// The key returned by codingKey, and the key used to write Key Bindings. The key name as is.
struct KeyNameKey: CodingKey {
  let stringValue: String
  var intValue: Int? { nil }

  init(stringValue: String) {
    self.stringValue = stringValue
  }

  init?(intValue: Int) { nil }
}
