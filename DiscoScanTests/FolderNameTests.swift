//
//  FolderNameTests.swift
//  DiscoScanTests
//

import Testing
@testable import DiscoScan

struct FolderNameTests {

    @Test func validatedRejectsEmptyAndWhitespace() {
        #expect(FolderName.validated(from: "") == .failure(.empty))
        #expect(FolderName.validated(from: "   ") == .failure(.empty))
        #expect(FolderName.validated(from: "\n\t") == .failure(.empty))
    }

    @Test func validatedTrimsWhitespace() throws {
        let result = FolderName.validated(from: "  Jazz  ")
        let folderName = try #require(try result.get())
        #expect(folderName.value == "Jazz")
    }

    @Test func validatedAcceptsNonEmptyName() throws {
        let result = FolderName.validated(from: "New Folder")
        let folderName = try #require(try result.get())
        #expect(folderName.value == "New Folder")
    }
}
