import Foundation

public struct DateFormat: Codable {
  public var format: String
  public var locale: String

  /// A DateFormatter built from this format.
  public var formatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: locale)
    formatter.dateFormat = format
    return formatter
  }
}
