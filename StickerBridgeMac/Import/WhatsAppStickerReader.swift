import Foundation
import SQLite3

protocol WhatsAppStickerReading: Sendable {
    func load(from containerURL: URL) throws -> [MacWhatsAppPack]
}

struct WhatsAppStickerReader: WhatsAppStickerReading {
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
        let databaseURL = root.appendingPathComponent("Sticker.sqlite")
        let stickersURL = root.appendingPathComponent(
            "stickers",
            isDirectory: true
        )
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: databaseURL.path,
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

        let database = try ReadOnlySQLite(url: databaseURL)
        try validateSchema(database)
        try database.execute("BEGIN DEFERRED TRANSACTION")
        defer { try? database.execute("ROLLBACK") }

        let entities: [Int64] = try database.rows(
            "SELECT Z_ENT FROM Z_PRIMARYKEY WHERE Z_NAME = 'WACDStickerPack' LIMIT 1"
        ) {
            ReadOnlySQLite.int64($0, 0)
        }
        guard let installedEntity = entities.first else {
            throw WhatsAppMVPError.missingInstalledPackEntity
        }

        let rows: [Row] = try database.rows(
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
                sqlite3_bind_int64($0, 1, installedEntity)
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
        guard !packs.isEmpty else {
            throw WhatsAppMVPError.noLocalPacks
        }
        return packs
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

    private func validateSchema(_ database: ReadOnlySQLite) throws {
        let required: [String: Set<String>] = [
            "Z_PRIMARYKEY": ["Z_ENT", "Z_NAME"],
            "ZWACDABSTRACTSTICKERPACK": [
                "Z_PK", "Z_ENT", "ZORDER", "ZNAME", "ZPUBLISHER"
            ],
            "ZWACDSTICKER": [
                "Z_PK", "ZSTICKERPACK", "ZSORT",
                "ZRELATIVEIMAGEPATH", "ZEMOJIS"
            ]
        ]
        let tables = Set(try database.rows(
            "SELECT name FROM sqlite_master WHERE type = 'table'"
        ) {
            ReadOnlySQLite.text($0, 0) ?? ""
        })
        for table in required.keys.sorted() where !tables.contains(table) {
            throw WhatsAppMVPError.missingTable(table)
        }
        for (table, columns) in required {
            let present = Set(try database.rows(
                "PRAGMA table_info(\(table))"
            ) {
                ReadOnlySQLite.text($0, 1) ?? ""
            })
            for column in columns.sorted()
            where !present.contains(column) {
                throw WhatsAppMVPError.missingColumn(
                    table: table,
                    column: column
                )
            }
        }
    }
}

private final class ReadOnlySQLite {
    private var handle: OpaquePointer?

    init(url: URL) throws {
        let result = sqlite3_open_v2(
            url.path,
            &handle,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX,
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
