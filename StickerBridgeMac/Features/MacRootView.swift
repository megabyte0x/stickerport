import AppKit
import SwiftUI

struct MacRootView: View {
    let store: MacBridgeStore
    @State private var showingSignalPrompt = false

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    private var isHostedUnitTesting: Bool {
        ProcessInfo.processInfo.environment[
            "XCTestConfigurationFilePath"
        ] != nil
    }

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
        .task {
            guard !isUITesting,
                  !isHostedUnitTesting,
                  store.phase == .disconnected else {
                return
            }
            await store.connect()
        }
        .onChange(of: store.phase) { _, newPhase in
            if newPhase == .finished {
                showingSignalPrompt = true
            }
        }
        .confirmationDialog(
            "Export complete",
            isPresented: $showingSignalPrompt,
            titleVisibility: .visible
        ) {
            Button("Open Signal Desktop") {
                store.openSignalDesktop()
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text(
                "The Stickers folder is open in Finder. Continue with File → Create/Upload Sticker Pack in Signal Desktop."
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .disconnected:
            HStack {
                ProgressView()
                Text("Preparing WhatsApp access")
            }

        case .loading:
            ProgressView("Reading WhatsApp sticker packs and Favorites")

        case .ready, .exporting, .finished:
            catalogEditor

        case .failed(let message):
            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .foregroundStyle(.red)
                Button("Try Again") {
                    Task {
                        store.startOver()
                        await store.connect()
                    }
                }
            }
        }
    }

    private var catalogEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            List {
                Section {
                    categoryActions(for: .stickerPacks)
                    if store.stickerPacks.isEmpty {
                        Text("No locally installed sticker packs found.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.stickerPacks) { pack in
                            Text(pack.title)
                                .font(.headline)
                            ForEach(pack.stickers) { sticker in
                                stickerToggle(sticker)
                            }
                        }
                    }
                } header: {
                    Text("Sticker Packs")
                        .accessibilityIdentifier("Sticker Packs Section")
                }

                Section {
                    categoryActions(for: .favorites)
                    if store.favorites.isEmpty {
                        Text("No supported Favorites found.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.favorites) { sticker in
                            stickerToggle(sticker)
                        }
                    }
                } header: {
                    Text("Favorites")
                        .accessibilityIdentifier("Favorites Section")
                }
            }
            .frame(minHeight: 320)
            .disabled(store.isExporting)

            HStack {
                Text("\(store.selectedStickerIDs.count) selected")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Export for Signal") {
                    Task { await store.createSignalFolder() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.canExport)
                .accessibilityIdentifier("Export for Signal")
            }

            if let selectionMessage = store.selectionMessage {
                Text(selectionMessage)
                    .foregroundStyle(.red)
            }

            if store.phase == .exporting {
                ProgressView("Creating Signal-ready folder")
            }

            if store.phase == .finished,
               let result = store.exportResult {
                Text(result.stickersURL.path)
                    .textSelection(.enabled)
                    .font(.caption)
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

    private func categoryActions(
        for category: MacStickerCategory
    ) -> some View {
        HStack {
            Button("Select All") {
                store.selectAll(in: category)
            }
            Button("Clear") {
                store.clearSelection(in: category)
            }
        }
    }

    private func stickerToggle(
        _ sticker: MacWhatsAppSticker
    ) -> some View {
        Toggle(
            isOn: Binding(
                get: {
                    store.selectedStickerIDs.contains(sticker.id)
                },
                set: {
                    store.setSticker(sticker.id, isSelected: $0)
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
