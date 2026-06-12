import Foundation

public enum UnlockedFileNameResolver {
    public static func outputURL(for inputURL: URL, fileManager: FileManager = .default) -> URL {
        let directory = inputURL.deletingLastPathComponent()
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        let firstCandidate = directory.appendingPathComponent("\(baseName)-unlock.pdf")

        guard fileManager.fileExists(atPath: firstCandidate.path) else {
            return firstCandidate
        }

        var index = 2
        while true {
            let candidate = directory.appendingPathComponent("\(baseName)-unlock-\(index).pdf")
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }
}
