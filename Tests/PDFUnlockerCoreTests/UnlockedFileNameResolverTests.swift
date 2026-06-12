import XCTest
@testable import PDFUnlockerCore

final class UnlockedFileNameResolverTests: XCTestCase {
    func testCreatesUnlockNameNextToOriginal() {
        let inputURL = URL(fileURLWithPath: "/tmp/Lecture 1.pdf")
        let outputURL = UnlockedFileNameResolver.outputURL(for: inputURL)
        XCTAssertEqual(outputURL.path, "/tmp/Lecture 1-unlock.pdf")
    }

    func testAvoidsOverwritingExistingUnlockFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("paper.pdf")
        let firstOutput = directory.appendingPathComponent("paper-unlock.pdf")
        let secondOutput = directory.appendingPathComponent("paper-unlock-2.pdf")
        FileManager.default.createFile(atPath: inputURL.path, contents: Data())
        FileManager.default.createFile(atPath: firstOutput.path, contents: Data())

        XCTAssertEqual(UnlockedFileNameResolver.outputURL(for: inputURL), secondOutput)
    }
}
