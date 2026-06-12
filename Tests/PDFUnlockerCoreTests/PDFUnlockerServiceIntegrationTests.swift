import XCTest
@testable import PDFUnlockerCore

final class PDFUnlockerServiceIntegrationTests: XCTestCase {
    func testUnlocksKnownPasswordPDFWhenQPDFAvailable() async throws {
        let dependency = QPDFDependency.detect()
        guard let qpdfURL = dependency.executableURL else {
            throw XCTSkip("qpdf is not installed")
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let plainURL = directory.appendingPathComponent("plain.pdf")
        let encryptedURL = directory.appendingPathComponent("lecture.pdf")

        try run(qpdfURL, arguments: ["--empty", plainURL.path])
        try run(qpdfURL, arguments: ["--encrypt", "secret", "owner", "256", "--", plainURL.path, encryptedURL.path])

        let result = try await PDFUnlockerService().unlockPDF(inputURL: encryptedURL, password: "secret")
        XCTAssertEqual(result.outputURL.lastPathComponent, "lecture-unlock.pdf")

        let encryptionStatus = try run(qpdfURL, arguments: ["--show-encryption", result.outputURL.path])
        XCTAssertTrue(encryptionStatus.contains("File is not encrypted"))
    }

    @discardableResult
    private func run(_ executableURL: URL, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "PDFUnlockerServiceIntegrationTests",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: [error, output].joined(separator: "\n")]
            )
        }

        return [output, error].joined(separator: "\n")
    }
}
