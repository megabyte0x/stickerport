import Foundation
import SQLite3

struct WhatsAppSQLiteFixture {
    let rootURL: URL
    let databaseURL: URL
    private let retainedWALConnection: RetainedSQLiteConnection?

    static func make(
        includeStickerTable: Bool = true,
        firstRelativePath: String = "pack/one.webp",
        installedPackEntity: Int64 = 2,
        relativeImagePathDeclaredType: String = "VARCHAR",
        leaveCommittedPackInWAL: Bool = false
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
        try execute(database, """
        CREATE TABLE Z_PRIMARYKEY (
          Z_ENT INTEGER PRIMARY KEY,
          Z_NAME VARCHAR
        );
        INSERT INTO Z_PRIMARYKEY
          VALUES (\(installedPackEntity), 'WACDStickerPack');

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
              ZRELATIVEIMAGEPATH \(relativeImagePathDeclaredType),
              ZEMOJIS VARCHAR,
              ZACCESSIBILITYTEXT VARCHAR,
              ZWIDTH INTEGER,
              ZHEIGHT INTEGER,
              ZMIMETYPE VARCHAR
            );
            INSERT INTO ZWACDSTICKER (
              Z_PK, ZSTICKERPACK, ZSORT,
              ZRELATIVEIMAGEPATH, ZEMOJIS
            )
              VALUES (101, 10, 1, 'pack/two.webp', '😂 😆');
            INSERT INTO ZWACDSTICKER (
              Z_PK, ZSTICKERPACK, ZSORT,
              ZRELATIVEIMAGEPATH, ZEMOJIS
            )
              VALUES (100, 10, 0, '\(escapedPath)', '☕ 🙂');
            """)
        }

        sqlite3_close(database)

        let retainedWALConnection: RetainedSQLiteConnection?
        if leaveCommittedPackInWAL {
            retainedWALConnection = try makeUncheckpointedWAL(
                databaseURL: databaseURL
            )
        } else {
            retainedWALConnection = nil
        }

        return WhatsAppSQLiteFixture(
            rootURL: root,
            databaseURL: databaseURL,
            retainedWALConnection: retainedWALConnection
        )
    }

    func close() {
        retainedWALConnection?.close()
    }

    private static func makeUncheckpointedWAL(
        databaseURL: URL
    ) throws -> RetainedSQLiteConnection {
        var database: OpaquePointer?
        guard sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK, let database else {
            throw CocoaError(.fileWriteUnknown)
        }
        do {
            try execute(database, "PRAGMA journal_mode = WAL")
            try execute(database, "PRAGMA wal_autocheckpoint = 0")
            try execute(database, """
            BEGIN IMMEDIATE;
            INSERT INTO ZWACDABSTRACTSTICKERPACK
              VALUES (12, 2, 2, 'WAL Fixture Pack', 'Fixture Publisher');
            INSERT INTO ZWACDSTICKER (
              Z_PK, ZSTICKERPACK, ZSORT,
              ZRELATIVEIMAGEPATH, ZEMOJIS
            )
              VALUES (102, 12, 0, 'pack/one.webp', '🧪');
            COMMIT;
            """)
            return RetainedSQLiteConnection(database)
        } catch {
            sqlite3_close(database)
            throw error
        }
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

private final class RetainedSQLiteConnection {
    private var database: OpaquePointer?

    init(_ database: OpaquePointer) {
        self.database = database
    }

    func close() {
        if let database {
            sqlite3_close(database)
            self.database = nil
        }
    }

    deinit {
        close()
    }
}
