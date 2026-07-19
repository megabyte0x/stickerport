import AppKit
import Foundation
import SQLite3

protocol WhatsAppStickerReading: Sendable {
    func load(from containerURL: URL) throws -> [MacWhatsAppPack]
}

struct WhatsAppStickerReader: WhatsAppStickerReading {
    private let expectedContainerURL: URL
    private let isWhatsAppRunning: @Sendable () -> Bool
    private let afterImmutableRead: @Sendable () -> Void

    init(
        expectedContainerURL: URL =
            WhatsAppContainerPicker.canonicalContainerURL,
        isWhatsAppRunning: @escaping @Sendable () -> Bool = {
            !NSRunningApplication.runningApplications(
                withBundleIdentifier: "net.whatsapp.WhatsApp"
            ).isEmpty
        },
        afterImmutableRead: @escaping @Sendable () -> Void = {}
    ) {
        self.expectedContainerURL = expectedContainerURL
        self.isWhatsAppRunning = isWhatsAppRunning
        self.afterImmutableRead = afterImmutableRead
    }

    func load(from containerURL: URL) throws -> [MacWhatsAppPack] {
        let started = containerURL.startAccessingSecurityScopedResource()
        defer {
            if started {
                containerURL.stopAccessingSecurityScopedResource()
            }
        }
        let root = containerURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let expectedRoot = expectedContainerURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
        guard root.path == expectedRoot.path else {
            throw WhatsAppMVPError.unexpectedContainer(
                expectedPath: expectedRoot.path
            )
        }
        let stickerDatabaseURL = root.appendingPathComponent("Sticker.sqlite")
        let favoritesDatabaseURL = root.appendingPathComponent(
            "BackedUpKeyValue.sqlite"
        )
        let stickersURL = root.appendingPathComponent(
            "stickers",
            isDirectory: true
        )
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: stickerDatabaseURL.path,
            isDirectory: &isDirectory
        ), !isDirectory.boolValue else {
            throw WhatsAppMVPError.missingDatabase
        }
        guard FileManager.default.fileExists(
            atPath: stickersURL.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue else {
            throw WhatsAppMVPError.missingStickerDirectory
        }
        let resolvedStickersURL = stickersURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
        guard isDescendant(resolvedStickersURL, of: root) else {
            throw WhatsAppMVPError.missingStickerDirectory
        }
        guard !isWhatsAppRunning() else {
            throw WhatsAppMVPError.whatsappIsRunning
        }

        var favoritesIsDirectory: ObjCBool = false
        let hasFavoritesDatabase = FileManager.default.fileExists(
            atPath: favoritesDatabaseURL.path,
            isDirectory: &favoritesIsDirectory
        ) && !favoritesIsDirectory.boolValue

        let stickerSnapshotBeforeRead = try SQLiteSnapshot.capture(
            databaseURL: stickerDatabaseURL
        )
        let favoritesSnapshotBeforeRead: SQLiteSnapshot? = hasFavoritesDatabase
            ? try SQLiteSnapshot.capture(databaseURL: favoritesDatabaseURL)
            : nil
        guard !stickerSnapshotBeforeRead.writeAheadLog.isNonempty,
              favoritesSnapshotBeforeRead?.writeAheadLog.isNonempty != true else {
            throw WhatsAppMVPError.uncheckpointedWriteAheadLog
        }

        let stickerDatabase = try ReadOnlySQLite(url: stickerDatabaseURL)
        let favoritesDatabase: ReadOnlySQLite? = hasFavoritesDatabase
            ? try ReadOnlySQLite(url: favoritesDatabaseURL)
            : nil

        try validateStickerSchema(stickerDatabase)
        if let favoritesDatabase {
            try validateColumnAffinities(
                VerifiedWhatsAppSchemaV26_28_22.favoriteColumnAffinities,
                in: favoritesDatabase
            )
        }

        try stickerDatabase.execute("BEGIN DEFERRED TRANSACTION")
        try favoritesDatabase?.execute("BEGIN DEFERRED TRANSACTION")
        defer {
            try? favoritesDatabase?.execute("ROLLBACK")
            try? stickerDatabase.execute("ROLLBACK")
        }

        let rows: [Row] = try stickerDatabase.rows(
            """
            SELECT
              p.Z_PK,
              COALESCE(p.ZNAME, ''),
              COALESCE(p.ZPUBLISHER, ''),
              s.Z_PK,
              COALESCE(s.ZSORT, 0),
              COALESCE(s.ZRELATIVEIMAGEPATH, ''),
              COALESCE(s.ZEMOJIS, '')
            FROM ZWACDABSTRACTSTICKERPACK p
            JOIN ZWACDSTICKER s ON s.ZSTICKERPACK = p.Z_PK
            WHERE p.Z_ENT = ?
            ORDER BY COALESCE(p.ZORDER, 0), p.Z_PK,
                     COALESCE(s.ZSORT, 0), s.Z_PK
            """,
            bind: {
                sqlite3_bind_int64(
                    $0,
                    1,
                    VerifiedWhatsAppSchemaV26_28_22.installedPackEntity
                )
            }
        ) {
            Row(
                packID: ReadOnlySQLite.int64($0, 0),
                title: ReadOnlySQLite.text($0, 1) ?? "",
                author: ReadOnlySQLite.text($0, 2) ?? "",
                stickerID: ReadOnlySQLite.int64($0, 3),
                order: ReadOnlySQLite.int($0, 4),
                relativePath: ReadOnlySQLite.text($0, 5) ?? "",
                rawEmoji: ReadOnlySQLite.text($0, 6) ?? ""
            )
        }

        var packOrder: [Int64] = []
        var grouped: [Int64: (Row, [MacWhatsAppSticker])] = [:]
        for row in rows {
            guard let mediaURL = safeStickerURL(
                relativePath: row.relativePath,
                stickersURL: resolvedStickersURL
            ), let data = try? Data(
                contentsOf: mediaURL,
                options: [.mappedIfSafe]
            ) else {
                continue
            }
            if grouped[row.packID] == nil {
                packOrder.append(row.packID)
                grouped[row.packID] = (row, [])
            }
            grouped[row.packID]?.1.append(
                MacWhatsAppSticker(
                    id: row.stickerID,
                    order: row.order,
                    relativePath: row.relativePath,
                    emoji: firstEmoji(row.rawEmoji),
                    data: data
                )
            )
        }

        let packs = packOrder.compactMap { packID -> MacWhatsAppPack? in
            guard let (first, stickers) = grouped[packID],
                  !stickers.isEmpty else {
                return nil
            }
            return MacWhatsAppPack(
                id: packID,
                title: first.title.isEmpty
                    ? "WhatsApp Stickers"
                    : first.title,
                author: first.author.isEmpty
                    ? "WhatsApp"
                    : first.author,
                stickers: stickers.sorted {
                    ($0.order, $0.id) < ($1.order, $1.id)
                }
            )
        }
        var sources = packs.map {
            MacWhatsAppPack(
                id: $0.id,
                category: .stickerPacks,
                title: $0.title,
                author: $0.author,
                stickers: $0.stickers
            )
        }

        if let favoritesDatabase {
            let favorites = try loadFavorites(
                membershipDatabase: favoritesDatabase,
                stickerDatabase: stickerDatabase,
                stickersURL: resolvedStickersURL
            )
            if !favorites.isEmpty {
                sources.insert(
                    MacWhatsAppPack(
                        id: MacWhatsAppPack.favoritesID,
                        category: .favorites,
                        title: "Favorites",
                        author: "WhatsApp",
                        stickers: favorites
                    ),
                    at: 0
                )
            }
        }

        try favoritesDatabase?.execute("ROLLBACK")
        try stickerDatabase.execute("ROLLBACK")

        afterImmutableRead()
        guard !isWhatsAppRunning() else {
            throw WhatsAppMVPError.whatsappIsRunning
        }
        guard try SQLiteSnapshot.capture(databaseURL: stickerDatabaseURL)
            == stickerSnapshotBeforeRead else {
            throw WhatsAppMVPError.sourceChangedDuringRead
        }
        if let favoritesSnapshotBeforeRead {
            guard try SQLiteSnapshot.capture(databaseURL: favoritesDatabaseURL)
                == favoritesSnapshotBeforeRead else {
                throw WhatsAppMVPError.sourceChangedDuringRead
            }
        }
        guard !sources.isEmpty else {
            throw WhatsAppMVPError.noLocalPacks
        }
        return sources
    }

    private struct Row {
        let packID: Int64
        let title: String
        let author: String
        let stickerID: Int64
        let order: Int
        let relativePath: String
        let rawEmoji: String
    }

    private struct FavoriteMembership {
        let fileHash: String
    }

    private struct FavoriteMediaRow {
        let stickerID: Int64
        let fileHash: String
        let relativePath: String
        let rawEmoji: String
        let mimeType: String
    }

    private func loadFavorites(
        membershipDatabase: ReadOnlySQLite,
        stickerDatabase: ReadOnlySQLite,
        stickersURL: URL
    ) throws -> [MacWhatsAppSticker] {
        let memberships: [FavoriteMembership] = try membershipDatabase.rows(
            """
            SELECT ZKEY
            FROM ZWAKEYVALUEELEMENT
            WHERE ZNAMESPACE = 'fs.v2'
              AND typeof(ZKEY) = 'text'
              AND length(ZKEY) = 44
              AND typeof(ZVALUE) = 'blob'
              AND length(ZVALUE) = 1
              AND hex(ZVALUE) = '01'
            ORDER BY ZSORT DESC, ZDATE DESC, Z_PK DESC
            """
        ) {
            FavoriteMembership(
                fileHash: ReadOnlySQLite.text($0, 0) ?? ""
            )
        }

        let mediaRows: [FavoriteMediaRow] = try stickerDatabase.rows(
            """
            SELECT
              Z_PK,
              COALESCE(ZFILEHASH, ''),
              COALESCE(ZRELATIVEIMAGEPATH, ''),
              COALESCE(ZEMOJIS, ''),
              COALESCE(ZMIMETYPE, '')
            FROM ZWACDSTICKER
            WHERE ZSTICKERPACK IS NULL
            """
        ) {
            FavoriteMediaRow(
                stickerID: ReadOnlySQLite.int64($0, 0),
                fileHash: ReadOnlySQLite.text($0, 1) ?? "",
                relativePath: ReadOnlySQLite.text($0, 2) ?? "",
                rawEmoji: ReadOnlySQLite.text($0, 3) ?? "",
                mimeType: ReadOnlySQLite.text($0, 4) ?? ""
            )
        }

        let rowsByHash = Dictionary(grouping: mediaRows, by: \.fileHash)
        var seenHashes: Set<String> = []
        var stickers: [MacWhatsAppSticker] = []

        for membership in memberships {
            guard seenHashes.insert(membership.fileHash).inserted,
                  let matches = rowsByHash[membership.fileHash],
                  matches.count == 1,
                  let row = matches.first,
                  row.mimeType == "image/webp",
                  let mediaURL = safeStickerURL(
                      relativePath: row.relativePath,
                      stickersURL: stickersURL
                  ),
                  let data = try? Data(
                      contentsOf: mediaURL,
                      options: [.mappedIfSafe]
                  ) else {
                continue
            }
            stickers.append(
                MacWhatsAppSticker(
                    id: row.stickerID,
                    order: stickers.count,
                    relativePath: row.relativePath,
                    emoji: firstEmoji(row.rawEmoji),
                    data: data
                )
            )
        }
        return stickers
    }

    private func firstEmoji(_ raw: String) -> String {
        raw.split(whereSeparator: \.isWhitespace)
            .first
            .map(String.init)
            ?? "🙂"
    }

    private func safeStickerURL(
        relativePath: String,
        stickersURL: URL
    ) -> URL? {
        guard !relativePath.isEmpty,
              !relativePath.hasPrefix("/"),
              !relativePath.split(separator: "/").contains("..") else {
            return nil
        }
        let root = stickersURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let candidate = root
            .appendingPathComponent(relativePath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let prefix = root.path.hasSuffix("/")
            ? root.path
            : root.path + "/"
        guard candidate.path.hasPrefix(prefix) else {
            return nil
        }
        let values = try? candidate.resourceValues(
            forKeys: [.isRegularFileKey]
        )
        return values?.isRegularFile == true ? candidate : nil
    }

    private func isDescendant(_ url: URL, of root: URL) -> Bool {
        let rootPath = root.path.hasSuffix("/")
            ? root.path
            : root.path + "/"
        return url.path.hasPrefix(rootPath)
    }

    private func validateStickerSchema(_ database: ReadOnlySQLite) throws {
        try validateColumnAffinities(
            VerifiedWhatsAppSchemaV26_28_22.requiredColumnAffinities,
            in: database
        )

        let installedPackEntities: [Int64] = try database.rows(
            """
            SELECT Z_ENT
            FROM Z_PRIMARYKEY
            WHERE Z_NAME = 'WACDStickerPack'
            ORDER BY Z_ENT
            """
        ) {
            ReadOnlySQLite.int64($0, 0)
        }
        guard installedPackEntities == [
            VerifiedWhatsAppSchemaV26_28_22.installedPackEntity
        ] else {
            throw WhatsAppMVPError.unsupportedSchema(
                "WACDStickerPack must map to Core Data entity 2."
            )
        }
    }

    private func validateColumnAffinities(
        _ required: [String: [String: SQLiteAffinity]],
        in database: ReadOnlySQLite
    ) throws {
        let tables = Set(try database.rows(
            "SELECT name FROM sqlite_master WHERE type = 'table'"
        ) {
            ReadOnlySQLite.text($0, 0) ?? ""
        })
        for table in required.keys.sorted()
        where !tables.contains(table) {
            throw WhatsAppMVPError.missingTable(table)
        }
        for (table, columns) in required {
            let present = Dictionary(uniqueKeysWithValues: try database.rows(
                "PRAGMA table_info(\(table))"
            ) {
                (
                    ReadOnlySQLite.text($0, 1) ?? "",
                    SQLiteAffinity(
                        declaredType: ReadOnlySQLite.text($0, 2) ?? ""
                    )
                )
            })
            for (column, expectedAffinity) in columns.sorted(
                by: { $0.key < $1.key }
            ) {
                guard let actualAffinity = present[column] else {
                    throw WhatsAppMVPError.missingColumn(
                        table: table,
                        column: column
                    )
                }
                guard actualAffinity == expectedAffinity else {
                    throw WhatsAppMVPError.unsupportedSchema(
                        "\(table).\(column) must have "
                            + "\(expectedAffinity.rawValue) affinity."
                    )
                }
            }
        }

    }
}

private struct SQLiteSnapshot: Equatable {
    let database: FileSnapshot
    let writeAheadLog: FileSnapshot
    let sharedMemory: FileSnapshot

    static func capture(databaseURL: URL) throws -> SQLiteSnapshot {
        try SQLiteSnapshot(
            database: FileSnapshot.capture(at: databaseURL),
            writeAheadLog: FileSnapshot.capture(
                at: URL(fileURLWithPath: databaseURL.path + "-wal")
            ),
            sharedMemory: FileSnapshot.capture(
                at: URL(fileURLWithPath: databaseURL.path + "-shm")
            )
        )
    }
}

private enum FileSnapshot: Equatable {
    case absent
    case bytes(Data)

    var isNonempty: Bool {
        guard case .bytes(let data) = self else {
            return false
        }
        return !data.isEmpty
    }

    static func capture(at url: URL) throws -> FileSnapshot {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .absent
        }
        do {
            return .bytes(try Data(contentsOf: url))
        } catch {
            throw WhatsAppMVPError.sqlite(
                "The database snapshot could not be read safely."
            )
        }
    }
}

private enum SQLiteAffinity: String {
    case integer = "INTEGER"
    case text = "TEXT"
    case blob = "BLOB"
    case real = "REAL"
    case numeric = "NUMERIC"

    init(declaredType: String) {
        let type = declaredType.uppercased()
        if type.contains("INT") {
            self = .integer
        } else if type.contains("CHAR")
                    || type.contains("CLOB")
                    || type.contains("TEXT") {
            self = .text
        } else if type.isEmpty || type.contains("BLOB") {
            self = .blob
        } else if type.contains("REAL")
                    || type.contains("FLOA")
                    || type.contains("DOUB") {
            self = .real
        } else {
            self = .numeric
        }
    }
}

private enum VerifiedWhatsAppSchemaV26_28_22 {
    static let installedPackEntity: Int64 = 2

    static let requiredColumnAffinities:
        [String: [String: SQLiteAffinity]] = [
            "Z_PRIMARYKEY": [
                "Z_ENT": .integer,
                "Z_NAME": .text
            ],
            "ZWACDABSTRACTSTICKERPACK": [
                "Z_PK": .integer,
                "Z_ENT": .integer,
                "ZORDER": .integer,
                "ZNAME": .text,
                "ZPUBLISHER": .text
            ],
            "ZWACDSTICKER": [
                "Z_PK": .integer,
                "ZSTICKERPACK": .integer,
                "ZSORT": .integer,
                "ZRELATIVEIMAGEPATH": .text,
                "ZEMOJIS": .text,
                "ZMIMETYPE": .text,
                "ZFILEHASH": .text
            ]
        ]

    static let favoriteColumnAffinities:
        [String: [String: SQLiteAffinity]] = [
            "ZWAKEYVALUEELEMENT": [
                "Z_PK": .integer,
                "ZSORT": .integer,
                "ZDATE": .numeric,
                "ZKEY": .text,
                "ZNAMESPACE": .text,
                "ZVALUE": .blob
            ]
        ]
}

private final class ReadOnlySQLite {
    private var handle: OpaquePointer?

    init(url: URL) throws {
        var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "mode", value: "ro"),
            URLQueryItem(name: "immutable", value: "1")
        ]
        guard let uri = components?.string else {
            throw WhatsAppMVPError.sqlite(
                "The database path could not be encoded safely."
            )
        }
        let result = sqlite3_open_v2(
            uri,
            &handle,
            SQLITE_OPEN_READONLY
                | SQLITE_OPEN_URI
                | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        guard result == SQLITE_OK, let handle else {
            let message = handle.map {
                String(cString: sqlite3_errmsg($0))
            } ?? "SQLite returned \(result)"
            if let handle {
                sqlite3_close(handle)
            }
            throw WhatsAppMVPError.sqlite(message)
        }
        sqlite3_busy_timeout(handle, 2_000)
        try execute("PRAGMA query_only = ON")
    }

    deinit {
        if let handle {
            sqlite3_close(handle)
        }
    }

    func execute(_ sql: String) throws {
        guard let handle else {
            throw WhatsAppMVPError.sqlite("Database is closed")
        }
        var errorPointer: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(
            handle,
            sql,
            nil,
            nil,
            &errorPointer
        ) == SQLITE_OK else {
            let message = errorPointer.map { String(cString: $0) }
                ?? String(cString: sqlite3_errmsg(handle))
            sqlite3_free(errorPointer)
            throw WhatsAppMVPError.sqlite(message)
        }
    }

    func rows<T>(
        _ sql: String,
        bind: (OpaquePointer) throws -> Void = { _ in },
        map: (OpaquePointer) throws -> T
    ) throws -> [T] {
        guard let handle else {
            throw WhatsAppMVPError.sqlite("Database is closed")
        }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            handle,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK, let statement else {
            throw WhatsAppMVPError.sqlite(
                String(cString: sqlite3_errmsg(handle))
            )
        }
        defer { sqlite3_finalize(statement) }
        try bind(statement)

        var values: [T] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                values.append(try map(statement))
            case SQLITE_DONE:
                return values
            default:
                throw WhatsAppMVPError.sqlite(
                    String(cString: sqlite3_errmsg(handle))
                )
            }
        }
    }

    static func int64(
        _ statement: OpaquePointer,
        _ index: Int32
    ) -> Int64 {
        sqlite3_column_int64(statement, index)
    }

    static func int(
        _ statement: OpaquePointer,
        _ index: Int32
    ) -> Int {
        Int(sqlite3_column_int(statement, index))
    }

    static func text(
        _ statement: OpaquePointer,
        _ index: Int32
    ) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let pointer = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: pointer)
    }
}
