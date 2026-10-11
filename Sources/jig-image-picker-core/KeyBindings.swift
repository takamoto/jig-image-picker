import Foundation

/// Table from Key Chord to Action. The keyBindings of the settings (key name -> action) are read as is.
public typealias KeyBindings = [KeyChord: Action]

extension KeyBindings {
  /// The Action for a pressed key. nil when nothing is bound.
  /// While Quick Look is showing, only Action.quickLookActions are taken; the rest pass through to the panel (nil).
  public func action(for chord: KeyChord, quickLookVisible: Bool) -> Action? {
    guard let action = self[chord] else { return nil }
    return quickLookVisible && !Action.quickLookActions.contains(action) ? nil : action
  }
}
