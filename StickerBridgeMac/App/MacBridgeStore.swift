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
    var phase: MacBridgePhase = .disconnected
    var packs: [MacWhatsAppPack] = []
    var selectedPackID: Int64?
    var selectedStickerIDs: Set<Int64> = []
    var exportResult: SignalFolderExport?
    var signalLaunchFailed = false

    private let whatsAppPicker: any WhatsAppFolderPicking
    private let reader: any WhatsAppStickerReading
    private let exportPicker: any ExportFolderPicking
    private let exporter: any SignalFolderExporting
    private let handoff: any SignalHandoffOpening

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
            && phase != .exporting
    }

    func connect() async {
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
            selectPack(first.id)
            phase = .ready
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func selectPack(_ id: Int64) {
        selectedPackID = id
        selectedStickerIDs = Set(
            packs.first(where: { $0.id == id })?
                .stickers
                .map(\.id)
                ?? []
        )
        exportResult = nil
        signalLaunchFailed = false
    }

    func setSticker(_ id: Int64, isSelected: Bool) {
        if isSelected {
            selectedStickerIDs.insert(id)
        } else {
            selectedStickerIDs.remove(id)
        }
        exportResult = nil
        if phase == .finished {
            phase = .ready
        }
    }

    func selectAll() {
        guard let selectedPack else {
            return
        }
        selectedStickerIDs = Set(selectedPack.stickers.map(\.id))
    }

    func clearSelection() {
        selectedStickerIDs = []
    }

    func createSignalFolder() async {
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
        phase = .exporting
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
            exportResult = result
            phase = .finished
            handoff.reveal(result.stickersURL)
        } catch {
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
        phase = .disconnected
        packs = []
        selectedPackID = nil
        selectedStickerIDs = []
        exportResult = nil
        signalLaunchFailed = false
    }
}
