import PDFUnlockerCore
import SwiftUI

struct HeaderView: View {
    let qpdfDependency: QPDFDependency
    let refreshAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "lock.open.document")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("PDF Unlocker")
                    .font(.title2.weight(.semibold))
                Text("Remove PDF encryption restrictions with qpdf and save a clean copy next to the original.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            QPDFStatusView(qpdfDependency: qpdfDependency, refreshAction: refreshAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }
}

private struct QPDFStatusView: View {
    let qpdfDependency: QPDFDependency
    let refreshAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Label(
                qpdfDependency.isInstalled ? "qpdf ready" : "qpdf missing",
                systemImage: qpdfDependency.isInstalled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.callout.weight(.medium))
            .foregroundStyle(qpdfDependency.isInstalled ? .green : .orange)

            Button(action: refreshAction) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh qpdf status")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
