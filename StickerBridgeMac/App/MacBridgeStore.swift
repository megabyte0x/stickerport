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
    private(set) var packs: [MacWhatsAppPack] = []
    private(set) var selectedPackID: Int64?
    private(set) var selectedStickerIDs: Set<Int64> = []
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

    var selectedPack: MacWhatsAppPack? {
        guard let selectedPackID else {
            return nil
        }
        return packs.first { $0.id == selectedPackID }
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
        guard let url = whatsAppPicker.chooseWhatsAppFolder() else {
            return
        }
        phase = .loading
        do {
            let reader = self.reader
            let loaded = try await Task.detached(
                priority: .userInitiated
            ) {
                try reader.load(from: url)
            }.value
            packs = loaded
            guard let first = loaded.first else {
                throw WhatsAppMVPError.noLocalPacks
            }
            authorizedInputRoot = canonicalized(url)
            selectPack(first.id)
            phase = .ready
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func selectPack(_ id: Int64) {
        guard !isExporting,
              let pack = packs.first(where: { $0.id == id }) else {
            return
        }
        selectedPackID = id
        replaceSelection(with: Set(pack.stickers.map(\.id)))
    }

    func setSticker(_ id: Int64, isSelected: Bool) {
        guard !isExporting else {
            return
        }
        var selection = selectedStickerIDs
        if isSelected {
            selection.insert(id)
        } else {
            selection.remove(id)
        }
        replaceSelection(with: selection)
    }

    func selectAll() {
        guard !isExporting, let selectedPack else {
            return
        }
        replaceSelection(with: Set(selectedPack.stickers.map(\.id)))
    }

    func clearSelection() {
        guard !isExporting else {
            return
        }
        replaceSelection(with: [])
    }

    func createSignalFolder() async {
        guard !isExporting else {
            return
        }
        guard let pack = selectedPack,
              !selectedStickerIDs.isEmpty else {
            phase = .failed("Select at least one sticker.")
            return
        }
        guard selectedStickerIDs.count <= 200 else {
            phase = .failed(
                "Signal packs support at most 200 stickers."
            )
            return
        }
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
            let ids = selectedStickerIDs
            let result = try await Task.detached(
                priority: .userInitiated
            ) {
                try exporter.export(
                    pack: pack,
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
        packs = []
        selectedPackID = nil
        selectedStickerIDs = []
        exportResult = nil
        signalLaunchFailed = false
        authorizedInputRoot = nil
    }

    private func replaceSelection(with selection: Set<Int64>) {
        selectedStickerIDs = selection
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
