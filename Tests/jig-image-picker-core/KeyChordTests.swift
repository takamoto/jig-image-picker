import AppKit
import Testing

@testable import JigImagePickerCore

@Suite struct KeyChordParsing {
  @Test func plainKey() {
    #expect(KeyChord(keyName: "return") == KeyChord(keyCode: 36, modifiers: []))
    #expect(KeyChord(keyName: "Escape") == KeyChord(keyCode: 53, modifiers: []))
  }

  @Test func modifiersInAnyOrder() {
    #expect(KeyChord(keyName: "cmd+y") == KeyChord(keyCode: 16, modifiers: .command))
    #expect(
      KeyChord(keyName: "shift+cmd+y")
        == KeyChord(keyCode: 16, modifiers: [.command, .shift]))
    #expect(KeyChord(keyName: "cmd+shift+y") == KeyChord(keyName: "shift+cmd+y"))
  }

  @Test func aliasesAndSymbols() {
    #expect(KeyChord(keyName: "⌃+N") == KeyChord(keyName: "control+n"))
    #expect(KeyChord(keyName: "alt+left") == KeyChord(keyName: "opt+left"))
    #expect(KeyChord(keyName: "esc") == KeyChord(keyName: "escape"))
    #expect(KeyChord(keyName: "keypadenter") == KeyChord(keyName: "enter"))
  }

  @Test func plusKeyIsSpelledOut() {
    #expect(KeyChord(keyName: "cmd+plus") == KeyChord(keyCode: 24, modifiers: .command))
  }

  @Test func whitespaceAroundPartsIsIgnored() {
    #expect(KeyChord(keyName: " cmd + y ") == KeyChord(keyName: "cmd+y"))
  }

  @Test func unparseable() {
    #expect(KeyChord(keyName: "") == nil)
    #expect(KeyChord(keyName: "bogus") == nil)
    #expect(KeyChord(keyName: "hyper+y") == nil)
    #expect(KeyChord(keyName: "cmd+") == nil)
  }
}

@Suite struct KeyChordNaming {
  @Test func canonicalSpelling() {
    #expect(KeyChord(keyName: "esc")!.keyName == "escape")
    #expect(KeyChord(keyName: "keypadenter")!.keyName == "enter")
    #expect(KeyChord(keyName: "backspace")!.keyName == "delete")
    #expect(KeyChord(keyName: "plus")!.keyName == "equal")
    #expect(KeyChord(keyName: "⌘+Y")!.keyName == "cmd+y")
  }

  @Test func modifiersInFixedOrder() {
    #expect(KeyChord(keyName: "cmd+shift+ctrl+alt+y")!.keyName == "ctrl+opt+shift+cmd+y")
  }

  @Test func unknownKeyCodeIsNumber() {
    #expect(KeyChord(keyCode: 10, modifiers: .command).keyName == "cmd+10")
  }

  @Test func codingKeyRoundTrips() {
    let chord = KeyChord(keyName: "shift+cmd+y")!
    #expect(chord.codingKey.stringValue == "shift+cmd+y")
    #expect(KeyChord(codingKey: chord.codingKey) == chord)
  }
}

@Suite struct KeyChordEquality {
  @Test func untrackedModifiersAreIgnored() {
    let arrow = KeyChord(keyCode: 123, modifiers: [.function, .numericPad])
    #expect(arrow == KeyChord(keyCode: 123, modifiers: []))
    #expect(arrow == KeyChord(keyName: "left"))
  }

  @Test func trackedModifiersMatter() {
    #expect(
      KeyChord(keyCode: 16, modifiers: .command) != KeyChord(keyCode: 16, modifiers: .control)
    )
  }
}
