import Foundation
import Yams

/// The whole settings file.
public struct SettingsFile: Decodable {
  public var defaultProfile: String?
  public var profiles: [String: Profile]

  /// Where it lives: JIG_IMAGE_PICKER_CONFIG, else ~/.config/jig-image-picker/config.yaml.
  public static func url(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    home: URL = FileManager.default.homeDirectoryForCurrentUser
  ) -> URL {
    if let path = environment["JIG_IMAGE_PICKER_CONFIG"], !path.isEmpty {
      return URL(expandingTilde: path)
    }
    return home.appendingPathComponent(".config/jig-image-picker/config.yaml")
  }
}

extension SettingsFile {
  /// Builds from a YAML string. On failure, throws with the offending item in the message.
  public init(yaml text: String) throws {
    do {
      self = try YAMLDecoder().decode(SettingsFile.self, from: text)
    } catch let error as DecodingError {
      throw SettingsFileError(decoding: error)
    } catch {
      throw SettingsFileError("not valid YAML: \(error)")
    }
    // An empty [EntrySource] decodes fine, so check it here
    if let name = profiles.keys.sorted().first(where: {
      profiles[$0]?.entrySources.isEmpty == true
    }) {
      throw SettingsFileError("profiles.\(name).entrySources: empty")
    }
  }

  /// Reads and builds from the settings file. The message is prefixed with the file name.
  public init(contentsOf url: URL) throws {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else {
      throw SettingsFileError("cannot read \(url.path)")
    }
    do {
      try self.init(yaml: text)
    } catch let error as SettingsFileError {
      throw SettingsFileError("\(url.lastPathComponent): \(error.description)")
    }
  }
}

public struct SettingsFileError: Error, CustomStringConvertible {
  public let description: String

  init(_ description: String) {
    self.description = description
  }

  /// Says which item of the settings file could not be read.
  init(decoding error: DecodingError) {
    /// Path to the item. An array index (a key with intValue) is appended to the previous key as `[0]`.
    func path(_ keys: [CodingKey]) -> String {
      guard !keys.isEmpty else { return "(root)" }
      return keys.reduce(into: "") { text, key in
        if let index = key.intValue {
          text += "[\(index)]"
        } else {
          text += (text.isEmpty ? "" : ".") + key.stringValue
        }
      }
    }
    switch error {
    case .keyNotFound(let key, let context):
      self.init("missing item: \(path(context.codingPath + [key]))")
    case .typeMismatch(_, let context), .valueNotFound(_, let context),
      .dataCorrupted(let context):
      self.init("\(path(context.codingPath)): \(context.debugDescription)")
    @unknown default:
      self.init("\(error)")
    }
  }
}
