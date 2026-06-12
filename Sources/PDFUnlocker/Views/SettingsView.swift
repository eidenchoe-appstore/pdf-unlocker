import PDFUnlockerCore
import SwiftUI

struct SettingsView: View {
    @State private var dependency = QPDFDependency.detect()

    var body: some View {
        Form {
            Section("qpdf") {
                LabeledContent("Status") {
                    Label(
                        dependency.isInstalled ? "Installed" : "Missing",
                        systemImage: dependency.isInstalled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(dependency.isInstalled ? .green : .orange)
                }

                LabeledContent("Path") {
                    Text(dependency.displayPath)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Refresh") {
                        dependency = QPDFDependency.detect()
                    }
                    Button("Copy Install Command") {
                        PasteboardWriter.copy(QPDFDependency.installCommand)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 520)
    }
}
