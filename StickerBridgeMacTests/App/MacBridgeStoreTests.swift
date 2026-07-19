import Foundation
import XCTest
@testable import StickerBridgeMac

@MainActor
final class MacBridgeStoreTests: XCTestCase {
    func testConnectStartsEmptyAndBulkSelectionIsIndependentByCategory()
        async {
        let favorite = makePack(
            id: MacWhatsAppPack.favoritesID,
            category: .favorites,
            firstStickerID: 100
        )
        let installed = makePack(
            id: 20,
            category: .stickerPacks,
            firstStickerID: 200
        )
        let store = makeStore(sources: [favorite, installed])

        await store.connect()

        XCTAssertEqual(store.phase, .ready)
        XCTAssertTrue(store.selectedStickerIDs.isEmpty)

        store.selectAll(in: .favorites)
        XCTAssertEqual(store.selectedStickerIDs, [100, 101])

        store.selectAll(in: .stickerPacks)
        XCTAssertEqual(store.selectedStickerIDs, [100, 101, 200, 201])

        store.clearSelection(in: .favorites)
        XCTAssertEqual(store.selectedStickerIDs, [200, 201])
    }

    func testManualSelectionCanCombinePacksAndFavorites() async {
        let favorite = makePack(
            id: MacWhatsAppPack.favoritesID,
            category: .favorites,
            firstStickerID: 100
        )
        let installed = makePack(
            id: 20,
            category: .stickerPacks,
            firstStickerID: 200
        )
        let store = makeStore(sources: [favorite, installed])
        await store.connect()

        store.setSticker(100, isSelected: true)
        store.setSticker(201, isSelected: true)

        XCTAssertEqual(store.selectedStickerIDs, [100, 201])
        XCTAssertEqual(store.selectedStickers.map(\.id), [201, 100])
        XCTAssertTrue(store.canExport)
    }

    func testDuplicateFavoriteAndPackStickerExportsOnce() async {
        let duplicate = MacWhatsAppSticker(
            id: 100,
            order: 0,
            relativePath: "duplicate.webp",
            emoji: "🙂",
            data: Data("duplicate".utf8)
        )
        let favorite = MacWhatsAppPack(
            id: MacWhatsAppPack.favoritesID,
            category: .favorites,
            title: "Favorites",
            author: "WhatsApp",
            stickers: [duplicate]
        )
        let installed = MacWhatsAppPack(
            id: 20,
            category: .stickerPacks,
            title: "Pack 20",
            author: "Author",
            stickers: [duplicate]
        )
        let store = makeStore(sources: [favorite, installed])
        await store.connect()

        store.selectAll(in: .stickerPacks)
        store.selectAll(in: .favorites)

        XCTAssertEqual(store.selectedStickerIDs, [100])
        XCTAssertEqual(store.selectedStickers.map(\.id), [100])
    }

    func testSelectAllDoesNotPartiallyApplyPastSignalLimit() async {
        let first = makePackWithStickerRange(
            id: 20,
            category: .stickerPacks,
            ids: 1...150
        )
        let second = makePackWithStickerRange(
            id: MacWhatsAppPack.favoritesID,
            category: .favorites,
            ids: 151...210
        )
        let store = makeStore(sources: [first, second])
        await store.connect()

        store.selectAll(in: .stickerPacks)
        store.selectAll(in: .favorites)

        XCTAssertEqual(store.selectedStickerIDs.count, 150)
        XCTAssertEqual(
            store.selectionMessage,
            "Signal supports at most 200 stickers. Choose fewer stickers."
        )
    }

    func testExportBlocksSelectionAndRepeatedExportUntilCompletion()
        async throws {
        let inputRoot = URL(fileURLWithPath: "/tmp/WhatsApp")
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: parent) }
        let packA = makePack()
        let packB = makePack(id: 20, firstStickerID: 200)
        let result = SignalFolderExport(
            rootURL: parent.appendingPathComponent("Pack-A"),
            stickersURL: parent.appendingPathComponent("Pack-A/Stickers")
        )
        let exporter = SuspendingExporter(result: result)
        let store = MacBridgeStore(
            whatsAppPicker: FakeWhatsAppPicker(url: inputRoot),
            reader: FakeWhatsAppReader(packs: [packA, packB]),
            exportPicker: FakeExportPicker(url: parent),
            exporter: exporter,
            handoff: RecordingHandoff()
        )
        await store.connect()
        for sticker in packA.stickers {
            store.setSticker(sticker.id, isSelected: true)
        }

        let exportTask = Task {
            await store.createSignalFolder()
        }
        await exporter.waitUntilStarted()
        XCTAssertEqual(store.phase, .exporting)

        store.setSticker(packA.stickers[0].id, isSelected: false)
        store.clearSelection(in: .stickerPacks)
        await store.createSignalFolder()

        XCTAssertEqual(
            store.selectedStickerIDs,
            Set(packA.stickers.map(\.id))
        )
        XCTAssertNil(store.exportResult)
        XCTAssertEqual(exporter.callCount, 1)

        exporter.resume()
        await exportTask.value

        XCTAssertEqual(store.phase, .finished)
        XCTAssertEqual(store.exportResult, result)
        XCTAssertEqual(
            store.sources.map(\.id),
            [packA.id, packB.id]
        )
    }

    func testRejectsExportAtOrInsideAuthorizedWhatsAppContainer() async {
        let inputRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let unsafeOutputs = [
            inputRoot,
            inputRoot.appendingPathComponent(
                "unsafe-output",
                isDirectory: true
            )
        ]

        for output in unsafeOutputs {
            let exporter = RecordingExporter(
                result: SignalFolderExport(
                    rootURL: output.appendingPathComponent("Result"),
                    stickersURL: output.appendingPathComponent(
                        "Result/Stickers"
                    )
                )
            )
            let store = MacBridgeStore(
                whatsAppPicker: FakeWhatsAppPicker(url: inputRoot),
                reader: FakeWhatsAppReader(packs: [makePack()]),
                exportPicker: FakeExportPicker(url: output),
                exporter: exporter,
                handoff: RecordingHandoff()
            )

            await store.connect()
            store.selectAll(in: .stickerPacks)
            await store.createSignalFolder()

            XCTAssertEqual(
                store.phase,
                .failed(
                    "Choose an export location outside WhatsApp’s shared container."
                )
            )
            XCTAssertEqual(exporter.callCount, 0)
        }
    }

    func testStaleExportCompletionCannotReplaceNewlyConnectedPack()
        async throws {
        let inputRoot = URL(fileURLWithPath: "/tmp/WhatsApp")
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: parent) }
        let packA = makePack()
        let packB = makePack(id: 20, firstStickerID: 200)
        let staleResult = SignalFolderExport(
            rootURL: parent.appendingPathComponent("Pack-A"),
            stickersURL: parent.appendingPathComponent("Pack-A/Stickers")
        )
        let exporter = SuspendingExporter(result: staleResult)
        let handoff = RecordingHandoff()
        let store = MacBridgeStore(
            whatsAppPicker: FakeWhatsAppPicker(url: inputRoot),
            reader: SequencedWhatsAppReader(
                responses: [[packA], [packB]]
            ),
            exportPicker: FakeExportPicker(url: parent),
            exporter: exporter,
            handoff: handoff
        )
        await store.connect()
        store.selectAll(in: .stickerPacks)

        let staleExportTask = Task {
            await store.createSignalFolder()
        }
        await exporter.waitUntilStarted()

        store.startOver()
        await store.connect()

        XCTAssertEqual(store.phase, .ready)
        XCTAssertEqual(store.sources.map(\.id), [packB.id])
        XCTAssertTrue(store.selectedStickerIDs.isEmpty)
        XCTAssertNil(store.exportResult)

        exporter.resume()
        await staleExportTask.value

        XCTAssertEqual(store.phase, .ready)
        XCTAssertEqual(store.sources.map(\.id), [packB.id])
        XCTAssertTrue(store.selectedStickerIDs.isEmpty)
        XCTAssertNil(store.exportResult)
        XCTAssertNil(handoff.revealedURL)
    }

    func testBulkSelectionInvalidatesFinishedExport() async throws {
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: parent) }
        let result = SignalFolderExport(
            rootURL: parent.appendingPathComponent("Result"),
            stickersURL: parent.appendingPathComponent("Result/Stickers")
        )
        let store = MacBridgeStore(
            whatsAppPicker: FakeWhatsAppPicker(
                url: URL(fileURLWithPath: "/tmp/WhatsApp")
            ),
            reader: FakeWhatsAppReader(packs: [makePack()]),
            exportPicker: FakeExportPicker(url: parent),
            exporter: RecordingExporter(result: result),
            handoff: RecordingHandoff()
        )
        await store.connect()
        store.selectAll(in: .stickerPacks)
        await store.createSignalFolder()
        XCTAssertEqual(store.phase, .finished)

        store.selectAll(in: .stickerPacks)

        XCTAssertEqual(store.phase, .ready)
        XCTAssertNil(store.exportResult)

        await store.createSignalFolder()
        XCTAssertEqual(store.phase, .finished)

        store.clearSelection(in: .stickerPacks)

        XCTAssertEqual(store.phase, .ready)
        XCTAssertNil(store.exportResult)
        XCTAssertTrue(store.selectedStickerIDs.isEmpty)
    }

    func testCombinedSelectionExportsOneGenericPack() async throws {
        let inputRoot = URL(fileURLWithPath: "/tmp/WhatsApp")
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: parent) }
        let result = SignalFolderExport(
            rootURL: parent.appendingPathComponent("Result"),
            stickersURL: parent.appendingPathComponent("Result/Stickers")
        )
        let exporter = RecordingExporter(result: result)
        let store = MacBridgeStore(
            whatsAppPicker: FakeWhatsAppPicker(url: inputRoot),
            reader: FakeWhatsAppReader(
                packs: [
                    makePack(
                        id: MacWhatsAppPack.favoritesID,
                        category: .favorites,
                        firstStickerID: 100
                    ),
                    makePack(
                        id: 20,
                        category: .stickerPacks,
                        firstStickerID: 200
                    )
                ]
            ),
            exportPicker: FakeExportPicker(url: parent),
            exporter: exporter,
            handoff: RecordingHandoff()
        )
        await store.connect()

        store.setSticker(100, isSelected: true)
        store.setSticker(201, isSelected: true)
        await store.createSignalFolder()

        let call = exporter.snapshot()
        XCTAssertEqual(call.packID, MacWhatsAppPack.combinedExportID)
        XCTAssertEqual(call.packTitle, "WhatsApp Selection")
        XCTAssertEqual(call.stickerIDs, [201, 100])
        XCTAssertEqual(call.selectedStickerIDs, [100, 201])
        XCTAssertEqual(store.phase, .finished)
    }

    private func makePack(
        id: Int64 = 10,
        category: MacStickerCategory = .stickerPacks,
        firstStickerID: Int64 = 100
    ) -> MacWhatsAppPack {
        MacWhatsAppPack(
            id: id,
            category: category,
            title: category == .favorites ? "Favorites" : "Pack \(id)",
            author: category == .favorites ? "WhatsApp" : "Author",
            stickers: [
                MacWhatsAppSticker(
                    id: firstStickerID,
                    order: 0,
                    relativePath: "one.webp",
                    emoji: "🙂",
                    data: Data("one".utf8)
                ),
                MacWhatsAppSticker(
                    id: firstStickerID + 1,
                    order: 1,
                    relativePath: "two.webp",
                    emoji: "😂",
                    data: Data("two".utf8)
                )
            ]
        )
    }

    private func makePackWithStickerRange(
        id: Int64,
        category: MacStickerCategory,
        ids: ClosedRange<Int64>
    ) -> MacWhatsAppPack {
        MacWhatsAppPack(
            id: id,
            category: category,
            title: category == .favorites ? "Favorites" : "Pack \(id)",
            author: "WhatsApp",
            stickers: ids.enumerated().map { offset, id in
                MacWhatsAppSticker(
                    id: id,
                    order: offset,
                    relativePath: "\(id).webp",
                    emoji: "🙂",
                    data: Data("\(id)".utf8)
                )
            }
        )
    }

    private func makeStore(
        sources: [MacWhatsAppPack]
    ) -> MacBridgeStore {
        MacBridgeStore(
            whatsAppPicker: FakeWhatsAppPicker(
                url: URL(fileURLWithPath: "/tmp/WhatsApp")
            ),
            reader: FakeWhatsAppReader(packs: sources),
            exportPicker: FakeExportPicker(url: nil),
            exporter: RecordingExporter(
                result: SignalFolderExport(
                    rootURL: URL(fileURLWithPath: "/tmp/Result"),
                    stickersURL: URL(fileURLWithPath: "/tmp/Result/Stickers")
                )
            ),
            handoff: RecordingHandoff()
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

private final class SequencedWhatsAppReader:
    WhatsAppStickerReading,
    @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [[MacWhatsAppPack]]

    init(responses: [[MacWhatsAppPack]]) {
        self.responses = responses
    }

    func load(from containerURL: URL) throws -> [MacWhatsAppPack] {
        lock.withLock {
            responses.removeFirst()
        }
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
        let packTitle: String
        let stickerIDs: [Int64]
        let selectedStickerIDs: Set<Int64>
        let parentURL: URL
    }

    private let lock = NSLock()
    private let result: SignalFolderExport
    private var call: Call?
    private var calls = 0

    init(result: SignalFolderExport) {
        self.result = result
    }

    func export(
        pack: MacWhatsAppPack,
        selectedStickerIDs: Set<Int64>,
        to parentURL: URL
    ) throws -> SignalFolderExport {
        lock.withLock {
            calls += 1
            call = Call(
                packID: pack.id,
                packTitle: pack.title,
                stickerIDs: pack.stickers.map(\.id),
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
                packTitle: "",
                stickerIDs: [],
                selectedStickerIDs: [],
                parentURL: URL(fileURLWithPath: "/")
            )
        }
    }

    var callCount: Int {
        lock.withLock { calls }
    }
}

private final class SuspendingExporter:
    SignalFolderExporting,
    @unchecked Sendable {
    private let result: SignalFolderExport
    private let release = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var calls = 0
    private var packIDs: [Int64] = []
    private var hasStarted = false
    private var startedContinuations: [
        CheckedContinuation<Void, Never>
    ] = []

    init(result: SignalFolderExport) {
        self.result = result
    }

    func export(
        pack: MacWhatsAppPack,
        selectedStickerIDs: Set<Int64>,
        to parentURL: URL
    ) throws -> SignalFolderExport {
        let continuations = lock.withLock {
            calls += 1
            packIDs.append(pack.id)
            hasStarted = true
            defer { startedContinuations.removeAll() }
            return startedContinuations
        }
        for continuation in continuations {
            continuation.resume()
        }
        release.wait()
        return result
    }

    func waitUntilStarted() async {
        await withCheckedContinuation { continuation in
            let shouldResume = lock.withLock {
                guard !hasStarted else {
                    return true
                }
                startedContinuations.append(continuation)
                return false
            }
            if shouldResume {
                continuation.resume()
            }
        }
    }

    func resume() {
        release.signal()
    }

    var callCount: Int {
        lock.withLock { calls }
    }

    var exportedPackIDs: [Int64] {
        lock.withLock { packIDs }
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
