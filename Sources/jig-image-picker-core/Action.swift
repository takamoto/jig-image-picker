import Foundation

/// An operation bound to a key. The values of keyBindings are exactly these names.
public enum Action: String, CaseIterable, Codable {
  case copy, cancel, quickLook, trash, previous, next, previousRow, nextRow

  /// Actions that stay active while Quick Look is open. The rest are passed through to Quick Look.
  static let quickLookActions: Set<Action> = [
    .previous, .next, .previousRow, .nextRow, .quickLook,
  ]
}
