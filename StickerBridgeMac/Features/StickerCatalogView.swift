import SwiftUI

struct StickerCatalogView: View {
    let store: MacBridgeStore

    private let columns = [
        GridItem(
            .adaptive(minimum: 96, maximum: 118),
            spacing: 14
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    stickerPacks
                    favorites

                    if store.phase == .finished {
                        ExportSuccessBanner(store: store)
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.automatic)
            .disabled(store.isExporting)

            ExportBar(store: store)
        }
        .stickerSurface(cornerRadius: 28, shadowRadius: 20)
        .clipShape(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    @ViewBuilder
    private var stickerPacks: some View {
        StickerCategoryHeader(
            title: "Sticker packs",
            systemImage: "square.stack.3d.up.fill",
            count: store.stickerPacks.flatMap(\.stickers).count,
            onSelectAll: {
                store.selectAll(in: .stickerPacks)
            },
            onClear: {
                store.clearSelection(in: .stickerPacks)
            }
        )

        if store.stickerPacks.isEmpty {
            EmptyStickerCategory(
                message: "No locally installed sticker packs found."
            )
        } else {
            ForEach(store.stickerPacks) { pack in
                StickerPackGrid(
                    pack: pack,
                    selectedStickerIDs: store.selectedStickerIDs,
                    isDisabled: store.isExporting,
                    columns: columns
                ) { id, isSelected in
                    store.setSticker(id, isSelected: isSelected)
                }
            }
        }
    }

    @ViewBuilder
    private var favorites: some View {
        StickerCategoryHeader(
            title: "Favorites",
            systemImage: "heart.fill",
            count: store.favorites.count,
            onSelectAll: {
                store.selectAll(in: .favorites)
            },
            onClear: {
                store.clearSelection(in: .favorites)
            }
        )

        if store.favorites.isEmpty {
            EmptyStickerCategory(
                message: "No supported Favorites found."
            )
        } else {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(store.favorites) { sticker in
                    StickerTileView(
                        sticker: sticker,
                        isSelected: store.selectedStickerIDs.contains(
                            sticker.id
                        ),
                        isDisabled: store.isExporting
                    ) {
                        store.setSticker(
                            sticker.id,
                            isSelected: !store.selectedStickerIDs.contains(
                                sticker.id
                            )
                        )
                    }
                }
            }
        }
    }
}

private struct StickerCategoryHeader: View {
    let title: String
    let systemImage: String
    let count: Int
    let onSelectAll: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(StickerTheme.coral)
                .frame(width: 28, height: 28)
                .background(
                    StickerTheme.coral.opacity(0.12),
                    in: RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                )

            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(StickerTheme.ink)

            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(StickerTheme.mutedInk)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    StickerTheme.indigo.opacity(0.09),
                    in: Capsule()
                )

            Spacer()

            Button("Select All", action: onSelectAll)
                .buttonStyle(.borderless)
            Button("Clear", action: onClear)
                .buttonStyle(.borderless)
                .foregroundStyle(StickerTheme.mutedInk)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(title) Section")
    }
}

private struct StickerPackGrid: View {
    let pack: MacWhatsAppPack
    let selectedStickerIDs: Set<Int64>
    let isDisabled: Bool
    let columns: [GridItem]
    let setSelection: (Int64, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(pack.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StickerTheme.mutedInk)
                    .lineLimit(1)
                Spacer()
                Text("\(pack.stickers.count) stickers")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(StickerTheme.mutedInk.opacity(0.78))
            }

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(pack.stickers) { sticker in
                    StickerTileView(
                        sticker: sticker,
                        isSelected: selectedStickerIDs.contains(sticker.id),
                        isDisabled: isDisabled
                    ) {
                        setSelection(
                            sticker.id,
                            !selectedStickerIDs.contains(sticker.id)
                        )
                    }
                }
            }
        }
        .padding(.top, 2)
    }
}

private struct EmptyStickerCategory: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "face.smiling")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(StickerTheme.mutedInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                StickerTheme.indigo.opacity(0.05),
                in: RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
    }
}

private struct ExportBar: View {
    let store: MacBridgeStore

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(StickerTheme.mint.opacity(0.22))
                    .frame(width: 42, height: 42)
                Text("\(store.selectedStickerIDs.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(StickerTheme.ink)
                    .contentTransition(.numericText())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(selectionTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(StickerTheme.ink)
                Text(selectionSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(
                        store.selectionMessage == nil
                            ? StickerTheme.mutedInk
                            : StickerTheme.coralDeep
                    )
                    .lineLimit(2)
            }

            Spacer()

            Button {
                Task { await store.createSignalFolder() }
            } label: {
                HStack(spacing: 8) {
                    if store.isExporting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up.forward.app.fill")
                    }
                    Text(
                        store.isExporting
                            ? "Creating Folder"
                            : "Create Signal Folder"
                    )
                }
            }
            .buttonStyle(StickerPrimaryButtonStyle())
            .disabled(!store.canExport)
            .opacity(store.canExport || store.isExporting ? 1 : 0.5)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("Export for Signal")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(StickerTheme.elevatedSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(StickerTheme.indigo.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var selectionTitle: String {
        store.selectedStickerIDs.isEmpty
            ? "Choose a few favorites"
            : "\(store.selectedStickerIDs.count) selected"
    }

    private var selectionSubtitle: String {
        store.selectionMessage
            ?? "Signal packs can include up to 200 stickers."
    }
}

private struct ExportSuccessBanner: View {
    let store: MacBridgeStore

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(StickerTheme.mint.opacity(0.24))
                    .frame(width: 46, height: 46)
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(StickerTheme.indigo)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Ready for Signal")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(StickerTheme.ink)
                Text("Your sticker folder is open in Finder.")
                    .font(.system(size: 12))
                    .foregroundStyle(StickerTheme.mutedInk)
            }

            Spacer()

            Button("Reveal Again") {
                store.revealStickers()
            }
            Button("Open Signal Desktop") {
                store.openSignalDesktop()
            }
            .buttonStyle(.borderedProminent)
            .tint(StickerTheme.indigo)
        }
        .padding(16)
        .background(
            StickerTheme.mint.opacity(0.11),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(StickerTheme.mint.opacity(0.28), lineWidth: 1)
        }
        .overlay(alignment: .bottomLeading) {
            if store.signalLaunchFailed {
                Text("Signal Desktop could not be opened.")
                    .font(.caption)
                    .foregroundStyle(StickerTheme.coralDeep)
                    .padding(.leading, 76)
                    .offset(y: 18)
            }
        }
    }
}
