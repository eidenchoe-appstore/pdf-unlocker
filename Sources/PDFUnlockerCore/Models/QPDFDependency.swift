import Foundation

public struct QPDFDependency: Equatable {
    public static let installCommand = "brew install qpdf"

    public let executableURL: URL?
    public let searchedPaths: [String]

    public var isInstalled: Bool {
        executableURL != nil
    }

    public var displayPath: String {
        executableURL?.path ?? "Not installed"
    }

    public static func detect(environment: [String: String] = ProcessInfo.processInfo.environment) -> QPDFDependency {
        let candidatePaths = candidateExecutablePaths(environment: environment)
        let fileManager = FileManager.default
        let executable = candidatePaths.first { path in
            fileManager.isExecutableFile(atPath: path)
        }.map { URL(fileURLWithPath: $0) }

        return QPDFDependency(executableURL: executable, searchedPaths: candidatePaths)
    }

    private static func candidateExecutablePaths(environment: [String: String]) -> [String] {
        var paths = [
            "/opt/homebrew/bin/qpdf",
            "/usr/local/bin/qpdf",
            "/opt/homebrew/sbin/qpdf",
            "/usr/local/sbin/qpdf"
        ]

        let pathEntries = environment["PATH"]?
            .split(separator: ":")
            .map(String.init) ?? []

        for entry in pathEntries {
            let candidate = URL(fileURLWithPath: entry)
                .appendingPathComponent("qpdf")
                .path
            if !paths.contains(candidate) {
                paths.append(candidate)
            }
        }

        return paths
    }
}
