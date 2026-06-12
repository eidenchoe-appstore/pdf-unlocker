import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: UnlockStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Jobs")
                    .font(.headline)
                Spacer()
                Button {
                    store.clearFinished()
                } label: {
                    Label("Clear Finished", systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(!store.hasJobs)
            }

            if store.jobs.isEmpty {
                EmptyHistoryView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.jobs) { job in
                            JobRow(job: job) {
                                store.revealOutput(for: job)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(minHeight: 150)
            }
        }
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Unlocked files will appear here.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color.primary.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct JobRow: View {
    let job: UnlockJob
    let revealAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: job.status.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(job.fileName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text(job.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(job.status.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
                .frame(width: 72, alignment: .trailing)

            Button {
                revealAction()
            } label: {
                Image(systemName: "arrow.up.forward.square")
            }
            .buttonStyle(.borderless)
            .help("Reveal output file")
            .disabled(job.outputURL == nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusColor: Color {
        switch job.status {
        case .queued:
            return .secondary
        case .running:
            return .blue
        case .succeeded:
            return .green
        case .failed:
            return .orange
        }
    }
}
