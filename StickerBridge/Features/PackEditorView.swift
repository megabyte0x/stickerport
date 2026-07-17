import SwiftUI

struct PackEditorView: View {
    let model: MVPBridgeModel
    @State private var draft: StickerPackDraft

    init(model: MVPBridgeModel, draft: StickerPackDraft) {
        self.model = model
        _draft = State(initialValue: draft)
    }

    var body: some View {
        Form {
            Section("Pack details") {
                TextField("Title", text: $draft.title)
                TextField("Author", text: $draft.author)
            }

            Section("Stickers") {
                ForEach($draft.stickers) { $sticker in
                    HStack {
                        TextField("Emoji", text: $sticker.emoji)
                            .frame(width: 72)
                            .accessibilityLabel("Emoji for \(URL(fileURLWithPath: sticker.relativePath).lastPathComponent)")
                        VStack(alignment: .leading) {
                            Text(URL(fileURLWithPath: sticker.relativePath).lastPathComponent)
                            Text("Static sticker")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            draft.coverStickerID = sticker.id
                        } label: {
                            Image(systemName: draft.coverStickerID == sticker.id ? "star.fill" : "star")
                        }
                        .accessibilityLabel(
                            draft.coverStickerID == sticker.id ? "Current cover sticker" : "Use as cover sticker"
                        )
                    }
                }
            }

            Section {
                Button("Prepare for Signal") {
                    Task { await model.prepare(draft) }
                }
                .disabled(draft.stickers.isEmpty || draft.stickers.count > SignalStickerRules.maximumStickerCount)

                Text("Static stickers are converted locally. Upload happens later in Signal Desktop.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ConversionStatusView(model: model)
        }
        .navigationTitle("Edit pack")
    }
}

private struct ConversionStatusView: View {
    let model: MVPBridgeModel

    @ViewBuilder
    var body: some View {
        switch model.phase {
        case .preparing:
            Section("Preparing") {
                ProgressView("Preparing stickers locally")
            }
        case .ready:
            if let pack = model.preparedPack {
                Section {
                    NavigationLink("Export for Signal Desktop") {
                        MVPExportView(model: model, pack: pack)
                    }
                }
            }
        case .failed(let message):
            Section("Could not prepare pack") {
                Text(message).foregroundStyle(.red)
            }
        default:
            EmptyView()
        }
    }
}
