import Foundation

public struct UnlockResult: Equatable {
    public let inputURL: URL
    public let outputURL: URL
    public let commandPath: String
    public let outputByteCount: UInt64

    public init(inputURL: URL, outputURL: URL, commandPath: String, outputByteCount: UInt64) {
        self.inputURL = inputURL
        self.outputURL = outputURL
        self.commandPath = commandPath
        self.outputByteCount = outputByteCount
    }
}
