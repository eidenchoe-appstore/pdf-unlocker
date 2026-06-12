import PDFUnlockerCore
import SwiftUI

struct DropZoneView: View {
    let isTargeted: Bool
    let qpdfInstalled: Bool
    let chooseAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: qpdfInstalled ? "doc.badge.arrow.up" : "terminal")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(qpdfInstalled ? .blue : .orange)
                .frame(width: 64, height: 64)

            VStack(spacing: 6) {
                Text(qpdfInstalled ? "Drop encrypted PDF files here" : "Install qpdf before unlocking")
                    .font(.title3.weight(.semibold))
                Text(qpdfInstalled ? "Output is saved as {filename}-unlock.pdf in the same folder." : QPDFDependency.installCommand)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button(action: chooseAction) {
                    Label("Choose PDF", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!qpdfInstalled)

                if !qpdfInstalled {
                    Button {
                        PasteboardWriter.copy(QPDFDependency.installCommand)
                    } label: {
                        Label("Copy Install Command", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .background(isTargeted ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: isTargeted ? 2 : 1.2, dash: [8, 7])
                )
        }
        .animation(.easeOut(duration: 0.16), value: isTargeted)
    }
}
