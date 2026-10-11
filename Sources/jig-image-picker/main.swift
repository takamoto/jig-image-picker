import AppKit
import ArgumentParser
import JigImagePickerCore

func isDirectory(_ url: URL) -> Bool {
  var flag: ObjCBool = false
  return FileManager.default.fileExists(atPath: url.path, isDirectory: &flag) && flag.boolValue
}

/// Prints a Spotlight Search for --check, and says so when the query is malformed.
func printCheck(of search: SpotlightSearch) {
  print("query: \(search.query)")
  print("scopes: \(search.scopes.joined(separator: ", "))")
  if !search.isQueryValid {
    print("invalid query: \(search.query)")
  }
}

/// Prints the reason to stderr and exits.
func fail(_ message: String) -> Never {
  fputs("jig-image-picker: \(message)\n", stderr)
  exit(1)
}

let arguments = Arguments.parseOrExit()
let settingsURL = SettingsFile.url()
let file: SettingsFile
do {
  file = try SettingsFile(contentsOf: settingsURL)
} catch {
  fail("\(error)")
}
guard let profileName = arguments.profile ?? file.defaultProfile else {
  fail("specify a profile name (there is no defaultProfile either)")
}
guard var profile = file.profiles[profileName] else {
  fail("no such profile: \(profileName)")
}

if arguments.check {
  print("settings: \(settingsURL.path)")
  print("profiles: \(file.profiles.keys.sorted().joined(separator: ", "))")
  print("profile: \(profileName)")
  print(profile)
  for source in profile.entrySources {
    switch source {
    case .directory(let path, _):
      let url = URL(expandingTilde: path)
      if !isDirectory(url) {
        print("missing directory: \(url.path)")
      }
    case .smartFolder(let path):
      do {
        printCheck(of: try SmartFolder(contentsOf: URL(expandingTilde: path)).search)
      } catch {
        print("cannot read smart folder: \(error)")
      }
    case .spotlightSearch(let query, let scopes):
      printCheck(of: SpotlightSearch(query: query, scopesAsWritten: scopes))
    }
  }
  print("images: \(Entry.load(from: profile.entrySources).count)")
  exit(0)
}

let controller = PickerController(profile: profile)
let application = NSApplication.shared
application.setActivationPolicy(.accessory)  // Keep out of the Dock
application.delegate = controller
application.run()
