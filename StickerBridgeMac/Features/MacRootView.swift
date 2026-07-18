import AppKit
import SwiftUI

struct MacRootView: View {
    let store: MacBridgeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prepare WhatsApp stickers for Signal")
                .font(.title2)
            Text("Everything stays on this Mac. StickerBridge never changes WhatsApp or uploads to Signal.")
                .foregroundStyle(.secondary)
            Divider()
            content
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 520)
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .disconnected:
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose WhatsApp’s sticker data folder.")
                Button("Connect WhatsApp") {
                    Task { await store.connect() }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("Connect WhatsApp")
            }

        case .loading:
            ProgressView("Reading local WhatsApp sticker packs")

        case .ready, .exporting, .finished:
            packEditor

        case .failed(let message):
            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .foregroundStyle(.red)
                Button("Start Over") {
                    store.startOver()
                }
            }
        }
    }

    @ViewBuilder
    private var packEditor: some View {
        if let pack = store.selectedPack {
            Picker(
                "WhatsApp pack",
                selection: Binding(
                    get: { store.selectedPackID ?? pack.id },
                    set: { store.selectPack($0) }
                )
            ) {
                ForEach(store.packs) {
                    Text("\($0.title) (\($0.stickers.count))")
                        .tag($0.id)
                }
            }
            .disabled(store.isExporting)

            HStack {
                Button("Select All") {
                    store.selectAll()
                }
                Button("Clear") {
                    store.clearSelection()
                }
                Spacer()
                Text("\(store.selectedStickerIDs.count) selected")
                    .foregroundStyle(.secondary)
            }
            .disabled(store.isExporting)

            List(pack.stickers) { sticker in
                Toggle(
                    isOn: Binding(
                        get: {
                            store.selectedStickerIDs.contains(
                                sticker.id
                            )
                        },
                        set: {
                            store.setSticker(
                                sticker.id,
                                isSelected: $0
                            )
                        }
                    )
                ) {
                    HStack(spacing: 12) {
                        thumbnail(sticker.data)
                        Text(sticker.emoji)
                        Text(
                            URL(fileURLWithPath: sticker.relativePath)
                                .lastPathComponent
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(minHeight: 260)
            .disabled(store.isExporting)

            HStack {
                Button("Create Signal-ready Folder") {
                    Task { await store.createSignalFolder() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.canExport)
                .accessibilityIdentifier(
                    "Create Signal-ready Folder"
                )

                if store.phase == .exporting {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if store.phase == .finished,
               let result = store.exportResult {
                Divider()
                Text("Folder created:")
                    .fontWeight(.semibold)
                Text(result.stickersURL.path)
                    .textSelection(.enabled)
                    .font(.caption)
                Text("In Signal Desktop: File → Create/Upload Sticker Pack → open this Stickers folder → press Command-A.")
                HStack {
                    Button("Reveal Stickers") {
                        store.revealStickers()
                    }
                    Button("Open Signal Desktop") {
                        store.openSignalDesktop()
                    }
                }
                if store.signalLaunchFailed {
                    Text("Signal Desktop is not installed or could not be opened.")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ data: Data) -> some View {
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
        } else {
            Image(systemName: "photo")
                .frame(width: 44, height: 44)
        }
    }
}
