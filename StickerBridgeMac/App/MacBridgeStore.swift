import Foundation
import Observation

enum MacBridgePhase: Equatable {
    case disconnected
    case loading
    case ready
    case exporting
    case finished
    case failed(String)
}

@MainActor
@Observable
final class MacBridgeStore {
    private(set) var phase: MacBridgePhase = .disconnected
    private(set) var sources: [MacWhatsAppPack] = []
    private(set) var selectedStickerIDs: Set<Int64> = []
    private(set) var selectionMessage: String?
    private(set) var exportResult: SignalFolderExport?
    private(set) var signalLaunchFailed = false

    private let whatsAppPicker: any WhatsAppFolderPicking
    private let reader: any WhatsAppStickerReading
    private let exportPicker: any ExportFolderPicking
    private let exporter: any SignalFolderExporting
    private let handoff: any SignalHandoffOpening
    private var authorizedInputRoot: URL?
    private var exportGeneration: UInt = 0

    init(
        whatsAppPicker: any WhatsAppFolderPicking,
        reader: any WhatsAppStickerReading,
        exportPicker: any ExportFolderPicking,
        exporter: any SignalFolderExporting,
        handoff: any SignalHandoffOpening
    ) {
        self.whatsAppPicker = whatsAppPicker
        self.reader = reader
        self.exportPicker = exportPicker
        self.exporter = exporter
        self.handoff = handoff
    }

    var stickerPacks: [MacWhatsAppPack] {
        sources.filter { $0.category == .stickerPacks }
    }

    var favorites: [MacWhatsAppSticker] {
        sources
            .first(where: { $0.category == .favorites })?
            .stickers ?? []
    }

    var selectedStickers: [MacWhatsAppSticker] {
        var seen: Set<Int64> = []
        return orderedAvailableStickers.filter {
            selectedStickerIDs.contains($0.id)
                && seen.insert($0.id).inserted
        }
    }

    private var orderedAvailableStickers: [MacWhatsAppSticker] {
        stickerPacks.flatMap(\.stickers) + favorites
    }

    private var availableStickerIDs: Set<Int64> {
        Set(orderedAvailableStickers.map(\.id))
    }

    var canExport: Bool {
        !selectedStickerIDs.isEmpty
            && selectedStickerIDs.count <= 200
            && (phase == .ready || phase == .finished)
    }

    var isExporting: Bool {
        phase == .exporting
    }

    func connect() async {
        guard phase != .loading, !isExporting else {
            return
        }
        phase = .loading
        guard let url = whatsAppPicker.chooseWhatsAppFolder() else {
            phase = .failed(
                "WhatsApp folder access is required. Choose Try Again to grant access."
            )
            return
        }
        do {
            let reader = self.reader
            let loaded = try await Task.detached(
                priority: .userInitiated
            ) {
                try reader.load(from: url)
            }.value
            guard !loaded.isEmpty else {
                throw WhatsAppMVPError.noLocalPacks
            }
            sources = loaded
            selectedStickerIDs = []
            selectionMessage = nil
            authorizedInputRoot = canonicalized(url)
            phase = .ready
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func sources(in category: MacStickerCategory) -> [MacWhatsAppPack] {
        sources.filter { $0.category == category }
    }

    func stickers(in category: MacStickerCategory) -> [MacWhatsAppSticker] {
        sources(in: category).flatMap(\.stickers)
    }

    func selectAll(in category: MacStickerCategory) {
        guard !isExporting else {
            return
        }
        let ids = Set(stickers(in: category).map(\.id))
        applySelection(selectedStickerIDs.union(ids))
    }

    func clearSelection(in category: MacStickerCategory) {
        guard !isExporting else {
            return
        }
        let ids = Set(stickers(in: category).map(\.id))
        applySelection(selectedStickerIDs.subtracting(ids))
    }

    func setSticker(_ id: Int64, isSelected: Bool) {
        guard !isExporting, availableStickerIDs.contains(id) else {
            return
        }
        var selection = selectedStickerIDs
        if isSelected {
            selection.insert(id)
        } else {
            selection.remove(id)
        }
        applySelection(selection)
    }

    func createSignalFolder() async {
        guard !isExporting else {
            return
        }
        let stickers = selectedStickers
        guard !stickers.isEmpty else {
            phase = .failed("Select at least one sticker.")
            return
        }
        guard stickers.count <= SignalStickerRules.maximumStickerCount else {
            phase = .failed(
                "Signal packs support at most 200 stickers."
            )
            return
        }
        let exportPack = MacWhatsAppPack(
            id: MacWhatsAppPack.combinedExportID,
            category: .stickerPacks,
            title: "WhatsApp Selection",
            author: "WhatsApp",
            stickers: stickers
        )
        guard let parent = exportPicker.chooseExportParent() else {
            return
        }
        guard let authorizedInputRoot,
              !isSameOrDescendant(
                canonicalized(parent),
                of: authorizedInputRoot
              ) else {
            phase = .failed(
                "Choose an export location outside WhatsApp’s shared container."
            )
            return
        }
        phase = .exporting
        exportGeneration &+= 1
        let operationGeneration = exportGeneration
        do {
            let exporter = self.exporter
            let ids = Set(stickers.map(\.id))
            let result = try await Task.detached(
                priority: .userInitiated
            ) {
                try exporter.export(
                    pack: exportPack,
                    selectedStickerIDs: ids,
                    to: parent
                )
            }.value
            guard operationGeneration == exportGeneration,
                  phase == .exporting else {
                return
            }
            exportResult = result
            phase = .finished
            handoff.reveal(result.stickersURL)
        } catch {
            guard operationGeneration == exportGeneration,
                  phase == .exporting else {
                return
            }
            phase = .failed(error.localizedDescription)
        }
    }

    func revealStickers() {
        guard let url = exportResult?.stickersURL else {
            return
        }
        handoff.reveal(url)
    }

    func openSignalDesktop() {
        signalLaunchFailed = !handoff.openSignalDesktop()
    }

    func startOver() {
        exportGeneration &+= 1
        phase = .disconnected
        sources = []
        selectedStickerIDs = []
        selectionMessage = nil
        exportResult = nil
        signalLaunchFailed = false
        authorizedInputRoot = nil
    }

    #if DEBUG
    func loadDesignPreview(
        sources: [MacWhatsAppPack],
        selectedStickerIDs: Set<Int64>
    ) {
        self.sources = sources
        self.selectedStickerIDs = selectedStickerIDs
        selectionMessage = nil
        exportResult = nil
        signalLaunchFailed = false
        authorizedInputRoot = URL(
            fileURLWithPath: "/tmp/StickerPortDesignPreview"
        )
        phase = .ready
    }
    #endif

    private func applySelection(_ selection: Set<Int64>) {
        guard selection.count <= SignalStickerRules.maximumStickerCount else {
            selectionMessage =
                "Signal supports at most 200 stickers. Choose fewer stickers."
            return
        }
        selectedStickerIDs = selection
        selectionMessage = nil
        exportResult = nil
        signalLaunchFailed = false
        if phase == .finished {
            phase = .ready
        }
    }

    private func canonicalized(_ url: URL) -> URL {
        url.resolvingSymlinksInPath().standardizedFileURL
    }

    private func isSameOrDescendant(_ url: URL, of root: URL) -> Bool {
        guard url.path != root.path else {
            return true
        }
        let rootPath = root.path.hasSuffix("/")
            ? root.path
            : root.path + "/"
        return url.path.hasPrefix(rootPath)
    }
}
