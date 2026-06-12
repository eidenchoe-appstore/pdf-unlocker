import AppKit
import Foundation
import PDFUnlockerCore

enum UnlockJobStatus: Equatable {
    case queued
    case running
    case succeeded
    case failed

    var label: String {
        switch self {
        case .queued:
            return "Queued"
        case .running:
            return "Unlocking"
        case .succeeded:
            return "Done"
        case .failed:
            return "Failed"
        }
    }

    var systemImage: String {
        switch self {
        case .queued:
            return "clock"
        case .running:
            return "arrow.triangle.2.circlepath"
        case .succeeded:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct UnlockJob: Identifiable, Equatable {
    let id = UUID()
    let inputURL: URL
    var outputURL: URL?
    var status: UnlockJobStatus = .queued
    var message: String = "Waiting to start"
    var createdAt: Date = Date()

    var fileName: String {
        inputURL.lastPathComponent
    }
}

@MainActor
final class UnlockStore: ObservableObject {
    @Published private(set) var jobs: [UnlockJob] = []
    @Published private(set) var qpdfDependency: QPDFDependency = .detect()
    @Published var lastDropMessage: String?

    private let service = PDFUnlockerService()

    var hasJobs: Bool {
        !jobs.isEmpty
    }

    func refreshQPDF() {
        qpdfDependency = service.detectQPDF()
    }

    func unlock(urls: [URL], password: String) {
        refreshQPDF()

        let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        guard !pdfURLs.isEmpty else {
            lastDropMessage = "Drop or select PDF files only."
            return
        }

        for url in pdfURLs {
            let job = UnlockJob(inputURL: url)
            jobs.insert(job, at: 0)

            Task {
                await run(jobID: job.id, inputURL: url, password: password)
            }
        }
    }

    func revealOutput(for job: UnlockJob) {
        guard let outputURL = job.outputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }

    func clearFinished() {
        jobs.removeAll { $0.status == .succeeded || $0.status == .failed }
    }

    private func run(jobID: UUID, inputURL: URL, password: String) async {
        update(jobID: jobID, status: .running, message: "Running qpdf")

        do {
            let result = try await service.unlockPDF(
                inputURL: inputURL,
                password: password.isEmpty ? nil : password
            )
            update(
                jobID: jobID,
                status: .succeeded,
                outputURL: result.outputURL,
                message: "Saved \(result.outputURL.lastPathComponent)"
            )
        } catch {
            update(
                jobID: jobID,
                status: .failed,
                message: error.localizedDescription
            )
        }
    }

    private func update(jobID: UUID, status: UnlockJobStatus, outputURL: URL? = nil, message: String) {
        guard let index = jobs.firstIndex(where: { $0.id == jobID }) else { return }
        jobs[index].status = status
        jobs[index].message = message
        if let outputURL {
            jobs[index].outputURL = outputURL
        }
    }
}
