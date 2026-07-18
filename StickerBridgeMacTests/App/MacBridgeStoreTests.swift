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

    func testExportBlocksPackSelectionAndRepeatedExportUntilCompletion()
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

        let exportTask = Task {
            await store.createSignalFolder()
        }
        await exporter.waitUntilStarted()
        XCTAssertEqual(store.phase, .exporting)

        store.selectPack(packB.id)
        store.clearSelection()
        store.setSticker(packA.stickers[0].id, isSelected: false)
        await store.createSignalFolder()

        XCTAssertEqual(store.selectedPackID, packA.id)
        XCTAssertEqual(
            store.selectedStickerIDs,
            Set(packA.stickers.map(\.id))
        )
        XCTAssertNil(store.exportResult)
        XCTAssertEqual(exporter.callCount, 1)

        exporter.resume()
        await exportTask.value

        XCTAssertEqual(store.phase, .finished)
        XCTAssertEqual(store.selectedPackID, packA.id)
        XCTAssertEqual(store.exportResult, result)
        XCTAssertEqual(exporter.exportedPackIDs, [packA.id])
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

        let staleExportTask = Task {
            await store.createSignalFolder()
        }
        await exporter.waitUntilStarted()

        store.startOver()
        await store.connect()

        XCTAssertEqual(store.phase, .ready)
        XCTAssertEqual(store.selectedPackID, packB.id)
        XCTAssertNil(store.exportResult)

        exporter.resume()
        await staleExportTask.value

        XCTAssertEqual(store.phase, .ready)
        XCTAssertEqual(store.selectedPackID, packB.id)
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
        await store.createSignalFolder()
        XCTAssertEqual(store.phase, .finished)

        store.selectAll()

        XCTAssertEqual(store.phase, .ready)
        XCTAssertNil(store.exportResult)

        await store.createSignalFolder()
        XCTAssertEqual(store.phase, .finished)

        store.clearSelection()

        XCTAssertEqual(store.phase, .ready)
        XCTAssertNil(store.exportResult)
        XCTAssertTrue(store.selectedStickerIDs.isEmpty)
    }

    private func makePack(
        id: Int64 = 10,
        firstStickerID: Int64 = 100
    ) -> MacWhatsAppPack {
        MacWhatsAppPack(
            id: id,
            title: "Pack \(id)",
            author: "Author",
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
