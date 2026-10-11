import Foundation
import Testing

@testable import JigImagePickerCore

@Suite struct URLExpandingTilde {
  let home = FileManager.default.homeDirectoryForCurrentUser.path

  @Test func expandsLeadingTilde() {
    #expect(URL(expandingTilde: "~/Pictures").path == "\(home)/Pictures")
    #expect(URL(expandingTilde: "~").path == home)
  }

  @Test func leavesOtherPathsAlone() {
    #expect(URL(expandingTilde: "/pics").path == "/pics")
    #expect(URL(expandingTilde: "/a/~/b").path == "/a/~/b")
  }
}
