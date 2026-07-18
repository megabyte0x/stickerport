import Foundation
import SQLite3

struct WhatsAppSQLiteFixture {
    let rootURL: URL
    let databaseURL: URL

    static func make(
        includeStickerTable: Bool = true,
        firstRelativePath: String = "pack/one.webp"
    ) throws -> WhatsAppSQLiteFixture {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stickerDirectory = root
            .appendingPathComponent("stickers/pack", isDirectory: true)
        try FileManager.default.createDirectory(
            at: stickerDirectory,
            withIntermediateDirectories: true
        )
        try Data("first".utf8).write(
            to: stickerDirectory.appendingPathComponent("one.webp")
        )
        try Data("second".utf8).write(
            to: stickerDirectory.appendingPathComponent("two.webp")
        )

        let databaseURL = root.appendingPathComponent("Sticker.sqlite")
        var database: OpaquePointer?
        guard sqlite3_open(databaseURL.path, &database) == SQLITE_OK,
              let database else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer { sqlite3_close(database) }

        try execute(database, """
        CREATE TABLE Z_PRIMARYKEY (
          Z_ENT INTEGER PRIMARY KEY,
          Z_NAME VARCHAR
        );
        INSERT INTO Z_PRIMARYKEY VALUES (2, 'WACDStickerPack');

        CREATE TABLE ZWACDABSTRACTSTICKERPACK (
          Z_PK INTEGER PRIMARY KEY,
          Z_ENT INTEGER,
          ZORDER INTEGER,
          ZNAME VARCHAR,
          ZPUBLISHER VARCHAR
        );
        INSERT INTO ZWACDABSTRACTSTICKERPACK
          VALUES (10, 2, 0, 'Fixture Pack', 'Fixture Publisher');
        INSERT INTO ZWACDABSTRACTSTICKERPACK
          VALUES (11, 3, 1, 'Catalog Pack', 'Store Publisher');
        """)

        if includeStickerTable {
            let escapedPath = firstRelativePath
                .replacingOccurrences(of: "'", with: "''")
            try execute(database, """
            CREATE TABLE ZWACDSTICKER (
              Z_PK INTEGER PRIMARY KEY,
              ZSTICKERPACK INTEGER,
              ZSORT INTEGER,
              ZRELATIVEIMAGEPATH VARCHAR,
              ZEMOJIS VARCHAR
            );
            INSERT INTO ZWACDSTICKER
              VALUES (101, 10, 1, 'pack/two.webp', '😂 😆');
            INSERT INTO ZWACDSTICKER
              VALUES (100, 10, 0, '\(escapedPath)', '☕ 🙂');
            """)
        }

        return WhatsAppSQLiteFixture(
            rootURL: root,
            databaseURL: databaseURL
        )
    }

    private static func execute(
        _ database: OpaquePointer,
        _ sql: String
    ) throws {
        var errorPointer: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(
            database,
            sql,
            nil,
            nil,
            &errorPointer
        ) == SQLITE_OK else {
            let message = errorPointer.map { String(cString: $0) }
                ?? "SQLite fixture failure"
            sqlite3_free(errorPointer)
            throw NSError(
                domain: "WhatsAppSQLiteFixture",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }
}
