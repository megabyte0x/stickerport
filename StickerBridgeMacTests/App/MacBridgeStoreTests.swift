import Foundation
import XCTest
@testable import StickerBridgeMac

@MainActor
final class MacBridgeStoreTests: XCTestCase {
    func testConnectSelectsAllAndExportUsesManualSelection() async throws {
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: parent) }
        let stickersURL = parent.appendingPathComponent(
            "Result/Stickers",
            isDirectory: true
        )
        let result = SignalFolderExport(
            rootURL: stickersURL.deletingLastPathComponent(),
            stickersURL: stickersURL
        )
        let pack = makePack()
        let exporter = RecordingExporter(result: result)
        let handoff = RecordingHandoff()
        let store = MacBridgeStore(
            whatsAppPicker: FakeWhatsAppPicker(
                url: URL(fileURLWithPath: "/tmp/WhatsApp")
            ),
            reader: FakeWhatsAppReader(packs: [pack]),
            exportPicker: FakeExportPicker(url: parent),
            exporter: exporter,
            handoff: handoff
        )

        await store.connect()

        XCTAssertEqual(store.phase, .ready)
        XCTAssertEqual(store.selectedStickerIDs, [100, 101])

        store.setSticker(100, isSelected: false)
        await store.createSignalFolder()

        XCTAssertEqual(store.phase, .finished)
        XCTAssertEqual(exporter.snapshot().selectedStickerIDs, [101])
        XCTAssertEqual(handoff.revealedURL, stickersURL)
    }

    func testClearDisablesExportSelection() async {
        let pack = makePack()
        let store = MacBridgeStore(
            whatsAppPicker: FakeWhatsAppPicker(
                url: URL(fileURLWithPath: "/tmp/WhatsApp")
            ),
            reader: FakeWhatsAppReader(packs: [pack]),
            exportPicker: FakeExportPicker(url: nil),
            exporter: RecordingExporter(
                result: SignalFolderExport(
                    rootURL: URL(fileURLWithPath: "/tmp/Result"),
                    stickersURL: URL(
                        fileURLWithPath: "/tmp/Result/Stickers"
                    )
                )
            ),
            handoff: RecordingHandoff()
        )

        await store.connect()
        store.clearSelection()

        XCTAssertTrue(store.selectedStickerIDs.isEmpty)
        XCTAssertFalse(store.canExport)
    }

    private func makePack() -> MacWhatsAppPack {
        MacWhatsAppPack(
            id: 10,
            title: "Pack",
            author: "Author",
            stickers: [
                MacWhatsAppSticker(
                    id: 100,
                    order: 0,
                    relativePath: "one.webp",
                    emoji: "🙂",
                    data: Data("one".utf8)
                ),
                MacWhatsAppSticker(
                    id: 101,
                    order: 1,
                    relativePath: "two.webp",
                    emoji: "😂",
                    data: Data("two".utf8)
                )
            ]
        )
    }
}

@MainActor
private struct FakeWhatsAppPicker: WhatsAppFolderPicking {
    let url: URL?

    func chooseWhatsAppFolder() -> URL? { url }
}

private struct FakeWhatsAppReader: WhatsAppStickerReading {
    let packs: [MacWhatsAppPack]

    func load(from containerURL: URL) throws -> [MacWhatsAppPack] {
        packs
    }
}

@MainActor
private struct FakeExportPicker: ExportFolderPicking {
    let url: URL?

    func chooseExportParent() -> URL? { url }
}

private final class RecordingExporter: SignalFolderExporting, @unchecked Sendable {
    struct Call: Equatable {
        let packID: Int64
        let selectedStickerIDs: Set<Int64>
        let parentURL: URL
    }

    private let lock = NSLock()
    private let result: SignalFolderExport
    private var call: Call?

    init(result: SignalFolderExport) {
        self.result = result
    }

    func export(
        pack: MacWhatsAppPack,
        selectedStickerIDs: Set<Int64>,
        to parentURL: URL
    ) throws -> SignalFolderExport {
        lock.withLock {
            call = Call(
                packID: pack.id,
                selectedStickerIDs: selectedStickerIDs,
                parentURL: parentURL
            )
        }
        return result
    }

    func snapshot() -> Call {
        lock.withLock {
            call ?? Call(
                packID: -1,
                selectedStickerIDs: [],
                parentURL: URL(fileURLWithPath: "/")
            )
        }
    }
}

@MainActor
private final class RecordingHandoff: SignalHandoffOpening {
    private(set) var revealedURL: URL?

    func reveal(_ url: URL) {
        revealedURL = url
    }

    func openSignalDesktop() -> Bool {
        true
    }
}
