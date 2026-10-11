import ArgumentParser
import Foundation
import Testing

@testable import JigImagePickerCore

@Suite struct ArgumentParsing {
  @Test func profileNameAndCheck() throws {
    let arguments = try Arguments.parse(["screenshots", "--check"])
    #expect(arguments.profile == "screenshots")
    #expect(arguments.check)
  }

  @Test func nothingIsRequired() throws {
    let arguments = try Arguments.parse([])
    #expect(arguments.profile == nil)
    #expect(!arguments.check)
  }
}
