import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var model = MVPBridgeModel()
    @State private var showsImporter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Prepare for Signal")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Choose static PNG or WebP sticker files you have permission to use. StickerBridge cannot read WhatsApp’s private library.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Import sticker files") {
                    showsImporter = true
                }
                .buttonStyle(.borderedProminent)

                if let draft = model.draft {
                    NavigationLink("Edit \(draft.stickers.count) imported stickers") {
                        PackEditorView(model: model, draft: draft)
                    }
                }

                if case .importing = model.phase {
                    ProgressView("Copying sticker files")
                }
                if case .failed(let message) = model.phase {
                    Text(message).foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("StickerBridge")
        }
        .fileImporter(
            isPresented: $showsImporter,
            allowedContentTypes: [.png, .webP],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task { await model.importURLs(urls) }
            case .failure(let error):
                model.phase = .failed(error.localizedDescription)
            }
        }
    }
}
