import ArgumentParser
import Foundation

public struct Arguments: ParsableArguments {
  @Argument(help: "Profile name. Defaults to defaultProfile.")
  public var profile: String?

  @Flag(help: "Print how the settings were read, without showing the window.")
  public var check = false

  public init() {}
}
