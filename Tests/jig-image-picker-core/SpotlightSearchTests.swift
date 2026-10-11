import Foundation
import Testing

@testable import JigImagePickerCore

@Suite struct SpotlightSearchQuery {
  @Test func wellFormedQueryIsValid() {
    let search = SpotlightSearch(
      query: "kMDItemContentTypeTree == \"public.image\"", scopes: ["kMDQueryScopeHome"])
    #expect(search.isQueryValid)
  }

  @Test func malformedQueryIsInvalid() {
    #expect(
      !SpotlightSearch(query: "kMDItemFSName ==", scopes: ["kMDQueryScopeHome"]).isQueryValid)
    #expect(!SpotlightSearch(query: "", scopes: ["kMDQueryScopeHome"]).isQueryValid)
  }
}

@Suite struct SpotlightSearchScopes {
  @Test func tildeIsExpandedAndConstantsAreKept() {
    let search = SpotlightSearch(
      query: "x == 1", scopesAsWritten: ["~/Pictures", "/Volumes/y", "kMDQueryScopeHome"])
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    #expect(search.scopes == ["\(home)/Pictures", "/Volumes/y", "kMDQueryScopeHome"])
  }
}
