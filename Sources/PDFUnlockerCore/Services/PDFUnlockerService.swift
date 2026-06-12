import Foundation

public struct PDFUnlockerService {
    public enum ServiceError: LocalizedError, Equatable {
        case qpdfMissing
        case inputMissing(String)
        case notPDF(String)
        case passwordRequired(String)
        case invalidPassword(String)
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
            case .passwordRequired(let fileName):
                return "\(fileName) requires a PDF password. Enter the known password and try again."
            case .invalidPassword(let fileName):
                return "The password was not accepted for \(fileName). Check the password and try again."
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

    let hasPassword = password?.isEmpty == false
    if !hasPassword {
        let passwordRequired = try requiresPassword(qpdfURL: qpdfURL, inputURL: inputURL)
        if passwordRequired {
            throw PDFUnlockerService.ServiceError.passwordRequired(inputURL.lastPathComponent)
        }
    }

    let outputURL = UnlockedFileNameResolver.outputURL(for: inputURL, fileManager: fileManager)

    var arguments: [String] = []
    if hasPassword, let password {
        arguments.append("--password=\(password)")
    }
    arguments.append("--decrypt")
    arguments.append(inputURL.path)
    arguments.append(outputURL.path)

    let result = try runQPDF(qpdfURL: qpdfURL, arguments: arguments)
    let message = result.sanitizedMessage(password: password)

    guard result.status == 0 else {
        try? fileManager.removeItem(at: outputURL)
        if message.localizedCaseInsensitiveContains("invalid password") {
            if hasPassword {
                throw PDFUnlockerService.ServiceError.invalidPassword(inputURL.lastPathComponent)
            }
            throw PDFUnlockerService.ServiceError.passwordRequired(inputURL.lastPathComponent)
        }
        throw PDFUnlockerService.ServiceError.qpdfFailed(status: result.status, message: message)
    }

    guard fileManager.fileExists(atPath: outputURL.path) else {
        throw PDFUnlockerService.ServiceError.outputMissing(outputURL.path)
    }

    let attributes = try fileManager.attributesOfItem(atPath: outputURL.path)
    let byteCount = attributes[.size] as? UInt64 ?? 0
    return UnlockResult(inputURL: inputURL, outputURL: outputURL, commandPath: qpdfURL.path, outputByteCount: byteCount)
}

private func requiresPassword(qpdfURL: URL, inputURL: URL) throws -> Bool {
    let result = try runQPDF(qpdfURL: qpdfURL, arguments: ["--requires-password", inputURL.path])
    return result.status == 0
}

private struct QPDFProcessResult {
    let status: Int32
    let standardOutput: String
    let standardError: String

    func sanitizedMessage(password: String?) -> String {
        sanitizeQPDFMessage(
            [standardError, standardOutput].filter { !$0.isEmpty }.joined(separator: "\n"),
            password: password
        )
    }
}

private func runQPDF(qpdfURL: URL, arguments: [String]) throws -> QPDFProcessResult {
    let process = Process()
    process.executableURL = qpdfURL
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
    return QPDFProcessResult(status: process.terminationStatus, standardOutput: standardOutput, standardError: standardError)
}

private func sanitizeQPDFMessage(_ message: String, password: String?) -> String {
    var sanitized = message.trimmingCharacters(in: .whitespacesAndNewlines)
    if let password, !password.isEmpty {
        sanitized = sanitized.replacingOccurrences(of: password, with: "********")
    }
    return sanitized
}
