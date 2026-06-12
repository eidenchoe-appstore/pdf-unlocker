import PDFUnlockerCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: UnlockStore
    @State private var isImporterPresented = false
    @State private var isDropTargeted = false
    @State private var password = ""

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(qpdfDependency: store.qpdfDependency) {
                store.refreshQPDF()
            }

            Divider()

            VStack(spacing: 18) {
                DropZoneView(
                    isTargeted: isDropTargeted,
                    qpdfInstalled: store.qpdfDependency.isInstalled,
                    chooseAction: { isImporterPresented = true }
                )
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop(providers:))

                PasswordInputView(password: $password)

                if let message = store.lastDropMessage {
                    Label(message, systemImage: "info.circle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                HistoryView()
                    .environmentObject(store)
            }
            .padding(24)
        }
        .background(.regularMaterial)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true,
            onCompletion: handleImport(result:)
        )
        .onAppear {
            store.refreshQPDF()
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectPDFRequested)) { _ in
            isImporterPresented = true
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            store.unlock(urls: urls, password: password)
        case .failure(let error):
            store.lastDropMessage = error.localizedDescription
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }

        guard !fileProviders.isEmpty else {
            store.lastDropMessage = "Drop PDF files from Finder."
            return false
        }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error {
                    Task { @MainActor in
                        store.lastDropMessage = error.localizedDescription
                    }
                    return
                }

                guard let url = decodeFileURL(from: item) else {
                    Task { @MainActor in
                        store.lastDropMessage = "Could not read the dropped file URL."
                    }
                    return
                }

                Task { @MainActor in
                    store.unlock(urls: [url], password: password)
                }
            }
        }

        return true
    }

    private func decodeFileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        if let string = item as? String {
            return URL(string: string)
        }
        return nil
    }
}
