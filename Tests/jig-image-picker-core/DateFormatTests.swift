import Foundation
import Testing

@testable import JigImagePickerCore

@Suite struct DateCaptions {
  @Test func formatterFollowsSettings() throws {
    let s = try testProfile("dateFormat: { format: yyyy-MM-dd, locale: en_US }")
    let formatter = s.dateFormat.formatter
    formatter.timeZone = TimeZone(identifier: "UTC")
    #expect(formatter.string(from: Date(timeIntervalSince1970: 0)) == "1970-01-01")
  }
}
