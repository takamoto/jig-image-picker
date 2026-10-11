import Testing

@testable import JigImagePickerCore

@Suite struct KeyBindingsFromSettings {
  @Test func keyNamesBecomeChords() throws {
    let s = try testProfile("keyBindings: { cmd+y: quickLook, Escape: cancel }")
    #expect(
      s.keyBindings == [
        KeyChord(keyName: "cmd+y")!: .quickLook, KeyChord(keyName: "escape")!: .cancel,
      ])
  }

  @Test func unreadableKeyNameFails() {
    let message = errorMessage { try testProfile("keyBindings: { hyper+x: copy }") }
    #expect(message?.hasPrefix("profiles.test.keyBindings.hyper+x: ") == true)
  }

  @Test func unknownActionFails() {
    let message = errorMessage { try testProfile("keyBindings: { cmd+f: fly }") }
    #expect(message?.hasPrefix("profiles.test.keyBindings.cmd+f: ") == true)
  }

  @Test func duplicateKeyNameFails() {
    #expect(
      errorMessage { try testProfile("keyBindings: { escape: cancel, escape: copy }") } != nil
    )
  }

  @Test func wrongShapeFails() {
    #expect(errorMessage { try testProfile("keyBindings: [cmd+y]") } != nil)
    #expect(errorMessage { try testProfile("keyBindings: { cmd+y: 1 }") } != nil)
  }
}

@Suite struct BoundActions {
  let keyBindings: KeyBindings = [
    KeyChord(keyName: "escape")!: .cancel,
    KeyChord(keyName: "right")!: .next,
  ]

  @Test func unboundKeyIsNil() {
    #expect(keyBindings.action(for: KeyChord(keyName: "a")!, quickLookVisible: false) == nil)
  }

  @Test func allActionsWhenQuickLookIsClosed() {
    #expect(
      keyBindings.action(for: KeyChord(keyName: "escape")!, quickLookVisible: false)
        == .cancel)
    #expect(
      keyBindings.action(for: KeyChord(keyName: "right")!, quickLookVisible: false) == .next)
  }

  @Test func onlyQuickLookActionsWhileQuickLookIsOpen() {
    #expect(
      keyBindings.action(for: KeyChord(keyName: "escape")!, quickLookVisible: true) == nil)
    #expect(
      keyBindings.action(for: KeyChord(keyName: "right")!, quickLookVisible: true) == .next)
  }
}
