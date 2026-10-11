import Foundation
import Testing

@testable import JigImagePickerCore

private let home = URL(fileURLWithPath: "/Users/someone")

@Suite struct SettingsFileLocation {
  @Test func defaultsToXDGPath() {
    #expect(
      SettingsFile.url(environment: [:], home: home).path
        == "/Users/someone/.config/jig-image-picker/config.yaml")
  }

  @Test func canBeOverridden() {
    #expect(
      SettingsFile.url(environment: ["JIG_IMAGE_PICKER_CONFIG": "/etc/p.yaml"], home: home)
        .path == "/etc/p.yaml")
    #expect(
      SettingsFile.url(environment: ["JIG_IMAGE_PICKER_CONFIG": ""], home: home).path
        .hasSuffix("config.yaml"))
  }

  @Test func overrideExpandsTilde() {
    let realHome = FileManager.default.homeDirectoryForCurrentUser.path
    #expect(
      SettingsFile.url(environment: ["JIG_IMAGE_PICKER_CONFIG": "~/p.yaml"], home: home).path
        == "\(realHome)/p.yaml")
  }
}

@Suite struct SettingsFileReading {
  @Test func unreadableFileFails() {
    let url = URL(fileURLWithPath: "/nonexistent/config.yaml")
    #expect(
      errorMessage { try SettingsFile(contentsOf: url) }
        == "cannot read /nonexistent/config.yaml")
  }

  @Test func brokenYAMLFails() throws {
    let url = scratchDirectory().appendingPathComponent("image-picker-\(UUID()).yaml")
    try Data("defaults: [".utf8).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    #expect(
      errorMessage { try SettingsFile(contentsOf: url) }?.hasPrefix(
        "\(url.lastPathComponent): ") == true)
  }

  @Test func fileIsRead() throws {
    let url = scratchDirectory().appendingPathComponent("image-picker-\(UUID()).yaml")
    let yaml =
      defaultsYAML
      + "defaultProfile: t\nprofiles:\n  t: { <<: *defaults, entrySources: [{ type: directory, path: /t, recursive: false }] }\n"
    try Data(yaml.utf8).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    let file = try SettingsFile(contentsOf: url)
    #expect(file.defaultProfile == "t")
    #expect(file.profiles.keys.sorted() == ["t"])
    #expect(file.profiles["t"]?.entrySources == [.directory(path: "/t", recursive: false)])
  }
}
