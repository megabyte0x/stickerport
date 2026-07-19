import XCTest
@testable import StickerBridgeMac

final class WhatsAppStickerReaderTests: XCTestCase {
    func testCanonicalContainerUsesSyntheticPOSIXLoginAccountHome() throws {
        let loginHome = try WhatsAppContainerPicker
            .resolvedLoginUserHomeDirectory(
                forUserID: 501,
                lookingUpHomeDirectory: { _ in "/Users/stickerbridge-fixture" }
            )
        let expected = WhatsAppContainerPicker.canonicalContainerURL(
            forLoginUserHomeDirectory: loginHome
        )

        XCTAssertEqual(
            expected.path,
            "/Users/stickerbridge-fixture/Library/Group Containers/" +
                "group.net.whatsapp.WhatsApp.shared"
        )
    }

    func testPOSIXHomeResolverRejectsMissingAccount() {
        XCTAssertThrowsError(
            try WhatsAppContainerPicker.resolvedLoginUserHomeDirectory(
                forUserID: 501,
                lookingUpHomeDirectory: { _ in nil }
            )
        ) {
            XCTAssertEqual(
                $0 as? LoginHomeDirectoryError,
                .missingAccount(501)
            )
        }
    }

    func testPOSIXHomeResolverRejectsRelativeHomePath() {
        XCTAssertThrowsError(
            try WhatsAppContainerPicker.resolvedLoginUserHomeDirectory(
                forUserID: 501,
                lookingUpHomeDirectory: { _ in "Users/stickerbridge" }
            )
        ) {
            XCTAssertEqual(
                $0 as? LoginHomeDirectoryError,
                .invalidPath("Users/stickerbridge")
            )
        }
    }

    func testPOSIXHomeResolverRejectsMalformedAbsoluteHomePaths() {
        let malformedPaths = [
            "//Users/stickerbridge",
            "/Users/stickerbridge/../other",
            "/Users/stickerbridge\u{0001}"
        ]

        for path in malformedPaths {
            XCTAssertThrowsError(
                try WhatsAppContainerPicker.resolvedLoginUserHomeDirectory(
                    forUserID: 501,
                    lookingUpHomeDirectory: { _ in path }
                )
            ) {
                XCTAssertEqual(
                    $0 as? LoginHomeDirectoryError,
                    .invalidPath(path)
                )
            }
        }
    }

    func testPOSIXLookupRetriesAtMaximumBufferBeforeFailing() {
        var requestedBufferSizes: [Int] = []

        XCTAssertThrowsError(
            try WhatsAppContainerPicker.posixLoginHomeDirectory(
                forUserID: 501,
                initialBufferSize: 700_000,
                maximumBufferSize: 1_048_576,
                lookingUpAccount: { _, bufferSize in
                    requestedBufferSizes.append(bufferSize)
                    return POSIXHomeDirectoryLookupResult(
                        status: ERANGE,
                        homeDirectoryPath: nil
                    )
                }
            )
        ) {
            XCTAssertEqual(
                $0 as? LoginHomeDirectoryError,
                .lookupFailed(ERANGE)
            )
        }
        XCTAssertEqual(requestedBufferSizes, [700_000, 1_048_576])
    }

    func testCanonicalContainerUsesLoginHomeRatherThanSandboxDataHome() {
        let loginHome = URL(
            fileURLWithPath: "/Users/stickerbridge-fixture",
            isDirectory: true
        )

        let container = WhatsAppContainerPicker.canonicalContainerURL(
            forLoginUserHomeDirectory: loginHome
        )

        XCTAssertEqual(
            container.path,
            "/Users/stickerbridge-fixture/Library/Group Containers/" +
                "group.net.whatsapp.WhatsApp.shared"
        )
    }

    func testLoadsOnlyInstalledPackRowsWithLocalMedia() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let databaseBefore = try Data(contentsOf: fixture.databaseURL)

        let packs = try reader(for: fixture).load(from: fixture.rootURL)

        XCTAssertEqual(packs.count, 1)
        XCTAssertEqual(packs[0].title, "Fixture Pack")
        XCTAssertEqual(packs[0].author, "Fixture Publisher")
        XCTAssertEqual(packs[0].stickers.map(\.order), [0, 1])
        XCTAssertEqual(packs[0].stickers.map(\.emoji), ["☕", "😂"])
        XCTAssertEqual(packs[0].stickers[0].data, Data("first".utf8))
        XCTAssertEqual(
            try Data(contentsOf: fixture.databaseURL),
            databaseBefore
        )
    }

    func testLoadsInstalledPacksAndRegularFavoritesAsSeparateCategories() throws {
        let fixture = try WhatsAppSQLiteFixture.make(includeFavorites: true)
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let before = try snapshot(of: fixture.rootURL)

        let sources = try reader(for: fixture).load(from: fixture.rootURL)

        XCTAssertEqual(sources.map(\.category), [.favorites, .stickerPacks])
        XCTAssertEqual(sources.map(\.title), ["Favorites", "Fixture Pack"])
        XCTAssertEqual(sources[0].id, MacWhatsAppPack.favoritesID)
        XCTAssertEqual(sources[0].stickers.map(\.id), [202, 201])
        XCTAssertEqual(sources[0].stickers.map(\.order), [0, 1])
        XCTAssertEqual(
            sources[0].stickers.map(\.data),
            [Data("favorite-new".utf8), Data("favorite-old".utf8)]
        )
        XCTAssertEqual(try snapshot(of: fixture.rootURL), before)
    }

    func testMissingFavoritesDatabaseKeepsInstalledPacksAvailable() throws {
        let fixture = try WhatsAppSQLiteFixture.make(includeFavorites: false)
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let sources = try reader(for: fixture).load(from: fixture.rootURL)

        XCTAssertEqual(sources.map(\.category), [.stickerPacks])
        XCTAssertEqual(sources.map(\.title), ["Fixture Pack"])
    }

    func testUnsupportedFavoriteRowsAreSkippedWithoutHidingInstalledPacks() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            includeFavorites: true,
            favoriteMembershipValueHex: "02"
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let sources = try reader(for: fixture).load(from: fixture.rootURL)

        XCTAssertEqual(sources.map(\.category), [.stickerPacks])
        XCTAssertEqual(sources.map(\.title), ["Fixture Pack"])
    }

    func testRejectsIfFavoritesDatabaseChangesDuringRead() throws {
        let fixture = try WhatsAppSQLiteFixture.make(includeFavorites: true)
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let favoritesSHM = URL(
            fileURLWithPath: fixture.favoritesDatabaseURL.path + "-shm"
        )
        let reader = WhatsAppStickerReader(
            expectedContainerURL: fixture.rootURL,
            isWhatsAppRunning: { false },
            afterImmutableRead: {
                try? Data("changed during read".utf8).write(to: favoritesSHM)
            }
        )

        XCTAssertThrowsError(try reader.load(from: fixture.rootURL)) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .sourceChangedDuringRead
            )
        }
    }

    func testRejectsAnUncheckpointedWALWithoutChangingAnySidecar() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            leaveCommittedPackInWAL: true
        )
        defer {
            fixture.close()
            try? FileManager.default.removeItem(at: fixture.rootURL)
        }
        let before = try snapshot(of: fixture.rootURL)

        XCTAssertNotNil(before.files["Sticker.sqlite-wal"])
        XCTAssertFalse(before.files["Sticker.sqlite-wal"]?.isEmpty ?? true)
        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .uncheckpointedWriteAheadLog
            )
        }

        XCTAssertEqual(try snapshot(of: fixture.rootURL), before)
    }

    func testRejectsWhileWhatsAppIsRunningBeforeOpeningDatabase() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let before = try snapshot(of: fixture.rootURL)
        let reader = WhatsAppStickerReader(
            expectedContainerURL: fixture.rootURL,
            isWhatsAppRunning: { true }
        )

        XCTAssertThrowsError(try reader.load(from: fixture.rootURL)) {
            XCTAssertEqual($0 as? WhatsAppMVPError, .whatsappIsRunning)
        }
        XCTAssertEqual(try snapshot(of: fixture.rootURL), before)
    }

    func testRejectsIfWhatsAppStartsDuringTheImmutableRead() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let runningState = RunningState(values: [false, true])
        let reader = WhatsAppStickerReader(
            expectedContainerURL: fixture.rootURL,
            isWhatsAppRunning: { runningState.next() }
        )

        XCTAssertThrowsError(try reader.load(from: fixture.rootURL)) {
            XCTAssertEqual($0 as? WhatsAppMVPError, .whatsappIsRunning)
        }
        XCTAssertEqual(runningState.callCount, 2)
    }

    func testRejectsAChangedSQLiteSnapshotAfterTheImmutableRead() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let sharedMemoryURL = URL(
            fileURLWithPath: fixture.databaseURL.path + "-shm"
        )
        let reader = WhatsAppStickerReader(
            expectedContainerURL: fixture.rootURL,
            isWhatsAppRunning: { false },
            afterImmutableRead: {
                try? Data("changed during read".utf8).write(
                    to: sharedMemoryURL
                )
            }
        )

        XCTAssertThrowsError(try reader.load(from: fixture.rootURL)) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .sourceChangedDuringRead
            )
        }
    }

    func testWrongContainerFailsBeforeReading() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        let expected = fixture.rootURL
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        XCTAssertThrowsError(
            try WhatsAppStickerReader(
                expectedContainerURL: expected
            ).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .unexpectedContainer(expectedPath: expected.path)
            )
        }
    }

    func testUnknownSchemaFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            includeStickerTable: false
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .missingTable("ZWACDSTICKER")
            )
        }
    }

    func testStickerPathCannotEscapeLocalStickerDirectory() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            firstRelativePath: "../Sticker.sqlite"
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let packs = try reader(for: fixture).load(from: fixture.rootURL)

        XCTAssertEqual(packs[0].stickers.count, 1)
        XCTAssertEqual(packs[0].stickers[0].emoji, "😂")
    }

    func testSymlinkedStickerDirectoryOutsideContainerFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make()
        let externalDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: fixture.rootURL)
            try? FileManager.default.removeItem(at: externalDirectory)
        }
        try FileManager.default.createDirectory(
            at: externalDirectory,
            withIntermediateDirectories: true
        )
        let stickersURL = fixture.rootURL.appendingPathComponent("stickers")
        try FileManager.default.removeItem(at: stickersURL)
        try FileManager.default.createSymbolicLink(
            at: stickersURL,
            withDestinationURL: externalDirectory
        )

        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual($0 as? WhatsAppMVPError, .missingStickerDirectory)
        }
    }

    func testMismatchedInstalledPackEntityFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            installedPackEntity: 9
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .unsupportedSchema(
                    "WACDStickerPack must map to Core Data entity 2."
                )
            )
        }
    }

    func testMismatchedColumnAffinityFailsClosed() throws {
        let fixture = try WhatsAppSQLiteFixture.make(
            relativeImagePathDeclaredType: "BLOB"
        )
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        XCTAssertThrowsError(
            try reader(for: fixture).load(from: fixture.rootURL)
        ) {
            XCTAssertEqual(
                $0 as? WhatsAppMVPError,
                .unsupportedSchema(
                    "ZWACDSTICKER.ZRELATIVEIMAGEPATH must have TEXT affinity."
                )
            )
        }
    }

    private func reader(
        for fixture: WhatsAppSQLiteFixture
    ) -> WhatsAppStickerReader {
        WhatsAppStickerReader(
            expectedContainerURL: fixture.rootURL,
            isWhatsAppRunning: { false }
        )
    }

    private func snapshot(of rootURL: URL) throws -> DirectorySnapshot {
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [],
            errorHandler: { _, _ in false }
        ) else {
            throw CocoaError(.fileReadUnknown)
        }
        var directories: Set<String> = ["."]
        var files: [String: Data] = [:]
        for case let url as URL in enumerator {
            let relativePath = String(
                url.path.dropFirst(rootURL.path.count + 1)
            )
            let values = try url.resourceValues(
                forKeys: [.isDirectoryKey]
            )
            if values.isDirectory == true {
                directories.insert(relativePath)
            } else {
                files[relativePath] = try Data(contentsOf: url)
            }
        }
        return DirectorySnapshot(
            directories: directories,
            files: files
        )
    }

    private struct DirectorySnapshot: Equatable {
        let directories: Set<String>
        let files: [String: Data]
    }

    private final class RunningState: @unchecked Sendable {
        private var values: [Bool]
        private(set) var callCount = 0

        init(values: [Bool]) {
            self.values = values
        }

        func next() -> Bool {
            callCount += 1
            return values.removeFirst()
        }
    }
}
