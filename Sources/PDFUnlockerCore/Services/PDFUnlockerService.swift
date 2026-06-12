import Foundation

public struct PDFUnlockerService {
    public enum ServiceError: LocalizedError, Equatable {
        case qpdfMissing
        case inputMissing(String)
        case notPDF(String)
        case processLaunchFailed(String)
        case qpdfFailed(status: Int32, message: String)
        case outputMissing(String)

        public var errorDescription: String? {
            switch self {
            case .qpdfMissing:
                return "qpdf is not installed. Install it with: \(QPDFDependency.installCommand)"
            case .inputMissing(let path):
                return "Input file was not found: \(path)"
            case .notPDF(let path):
                return "Only PDF files are supported: \(path)"
            case .processLaunchFailed(let message):
                return "Could not start qpdf: \(message)"
            case .qpdfFailed(_, let message):
                return message.isEmpty ? "qpdf could not unlock this PDF." : message
            case .outputMissing(let path):
                return "qpdf finished but did not create an output file: \(path)"
            }
        }
    }

    public init() {}

    public func detectQPDF() -> QPDFDependency {
        QPDFDependency.detect()
    }

    public func unlockPDF(inputURL: URL, password: String?) async throws -> UnlockResult {
        try await Task.detached(priority: .userInitiated) {
            try unlockPDFSync(inputURL: inputURL, password: password)
        }.value
    }
}

private func unlockPDFSync(inputURL: URL, password: String?) throws -> UnlockResult {
    let fileManager = FileManager.default
    guard inputURL.pathExtension.lowercased() == "pdf" else {
        throw PDFUnlockerService.ServiceError.notPDF(inputURL.path)
    }
    guard fileManager.fileExists(atPath: inputURL.path) else {
        throw PDFUnlockerService.ServiceError.inputMissing(inputURL.path)
    }

    let dependency = QPDFDependency.detect()
    guard let qpdfURL = dependency.executableURL else {
        throw PDFUnlockerService.ServiceError.qpdfMissing
    }

    let outputURL = UnlockedFileNameResolver.outputURL(for: inputURL, fileManager: fileManager)

    let process = Process()
    process.executableURL = qpdfURL

    var arguments: [String] = []
    if let password, !password.isEmpty {
        arguments.append("--password=\(password)")
    }
    arguments.append("--decrypt")
    arguments.append(inputURL.path)
    arguments.append(outputURL.path)
    process.arguments = arguments

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    do {
        try process.run()
    } catch {
        throw PDFUnlockerService.ServiceError.processLaunchFailed(error.localizedDescription)
    }

    process.waitUntilExit()

    let standardOutput = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let standardError = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let message = sanitizeQPDFMessage(
        [standardError, standardOutput].filter { !$0.isEmpty }.joined(separator: "\n"),
        password: password
    )

    guard process.terminationStatus == 0 else {
        try? fileManager.removeItem(at: outputURL)
        throw PDFUnlockerService.ServiceError.qpdfFailed(status: process.terminationStatus, message: message)
    }

    guard fileManager.fileExists(atPath: outputURL.path) else {
        throw PDFUnlockerService.ServiceError.outputMissing(outputURL.path)
    }

    let attributes = try fileManager.attributesOfItem(atPath: outputURL.path)
    let byteCount = attributes[.size] as? UInt64 ?? 0
    return UnlockResult(inputURL: inputURL, outputURL: outputURL, commandPath: qpdfURL.path, outputByteCount: byteCount)
}

private func sanitizeQPDFMessage(_ message: String, password: String?) -> String {
    var sanitized = message.trimmingCharacters(in: .whitespacesAndNewlines)
    if let password, !password.isEmpty {
        sanitized = sanitized.replacingOccurrences(of: password, with: "********")
    }
    return sanitized
}
