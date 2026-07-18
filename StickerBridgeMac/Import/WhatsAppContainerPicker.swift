import AppKit
import Darwin
import Foundation

@MainActor
protocol WhatsAppFolderPicking {
    func chooseWhatsAppFolder() -> URL?
}

@MainActor
struct WhatsAppContainerPicker: WhatsAppFolderPicking {
    nonisolated static var canonicalContainerURL: URL {
        canonicalContainerURL(
            forLoginUserHomeDirectory: loginUserHomeDirectory
        )
    }

    nonisolated static func canonicalContainerURL(
        forLoginUserHomeDirectory loginUserHomeDirectory: URL
    ) -> URL {
        loginUserHomeDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Group Containers", isDirectory: true)
            .appendingPathComponent(
                "group.net.whatsapp.WhatsApp.shared",
                isDirectory: true
            )
    }

    nonisolated static func isCanonicalContainer(_ url: URL) -> Bool {
        canonicalized(url).path == canonicalized(canonicalContainerURL).path
    }

    nonisolated static func resolvedLoginUserHomeDirectory(
        forUserID userID: uid_t,
        lookingUpHomeDirectory lookup: (uid_t) throws -> String?
    ) throws -> URL {
        guard let path = try lookup(userID) else {
            throw LoginHomeDirectoryError.missingAccount(userID)
        }
        guard path.hasPrefix("/"),
              !path.unicodeScalars.contains(
                  where: CharacterSet.controlCharacters.contains
              ) else {
            throw LoginHomeDirectoryError.invalidPath(path)
        }
        let homeDirectory = URL(
            fileURLWithPath: path,
            isDirectory: true
        ).standardizedFileURL
        guard homeDirectory.path == path else {
            throw LoginHomeDirectoryError.invalidPath(path)
        }
        return homeDirectory
    }

    nonisolated static func posixLoginHomeDirectory(
        forUserID userID: uid_t
    ) throws -> String? {
        let maximumBufferSize = 1_048_576
        let configuredBufferSize = max(
            Int(sysconf(_SC_GETPW_R_SIZE_MAX)),
            16_384
        )
        return try posixLoginHomeDirectory(
            forUserID: userID,
            initialBufferSize: min(configuredBufferSize, maximumBufferSize),
            maximumBufferSize: maximumBufferSize,
            lookingUpAccount: { userID, bufferSize in
                lookupPOSIXAccount(
                    forUserID: userID,
                    bufferSize: bufferSize
                )
            }
        )
    }

    nonisolated static func posixLoginHomeDirectory(
        forUserID userID: uid_t,
        initialBufferSize: Int,
        maximumBufferSize: Int,
        lookingUpAccount lookup: (uid_t, Int) -> POSIXHomeDirectoryLookupResult
    ) throws -> String? {
        precondition(maximumBufferSize > 0)
        var bufferSize = min(
            max(initialBufferSize, 1),
            maximumBufferSize
        )

        while true {
            let result = lookup(userID, bufferSize)
            if result.status != ERANGE {
                guard result.status == 0 else {
                    throw LoginHomeDirectoryError.lookupFailed(result.status)
                }
                return result.homeDirectoryPath
            }
            guard bufferSize < maximumBufferSize else {
                throw LoginHomeDirectoryError.lookupFailed(ERANGE)
            }
            bufferSize = min(
                bufferSize > maximumBufferSize / 2
                    ? maximumBufferSize
                    : bufferSize * 2,
                maximumBufferSize
            )
        }
    }

    func chooseWhatsAppFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose WhatsApp Sticker Data"
        panel.message = "Quit WhatsApp completely, then choose group.net.whatsapp.WhatsApp.shared. StickerBridge reads stickers only and never changes WhatsApp data."
        panel.prompt = "Connect WhatsApp"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = Self.canonicalContainerURL
        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }
        guard Self.isCanonicalContainer(url) else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Choose the WhatsApp shared container"
            alert.informativeText = WhatsAppMVPError.unexpectedContainer(
                expectedPath: Self.canonicalContainerURL.path
            ).localizedDescription
            alert.runModal()
            return nil
        }
        return url
    }

    private nonisolated static func canonicalized(_ url: URL) -> URL {
        url.resolvingSymlinksInPath().standardizedFileURL
    }

    private nonisolated static func lookupPOSIXAccount(
        forUserID userID: uid_t,
        bufferSize: Int
    ) -> POSIXHomeDirectoryLookupResult {
        var buffer = [CChar](repeating: 0, count: bufferSize)
        return buffer.withUnsafeMutableBufferPointer { buffer in
            var account = passwd()
            var accountPointer: UnsafeMutablePointer<passwd>?
            let status = getpwuid_r(
                userID,
                &account,
                buffer.baseAddress,
                buffer.count,
                &accountPointer
            )
            guard status == 0,
                  let homeDirectory = accountPointer?.pointee.pw_dir else {
                return POSIXHomeDirectoryLookupResult(
                    status: status,
                    homeDirectoryPath: nil
                )
            }
            return POSIXHomeDirectoryLookupResult(
                status: status,
                homeDirectoryPath: String(cString: homeDirectory)
            )
        }
    }

    /// Reads the macOS login account's record, not this app's sandbox Data home.
    private nonisolated static var loginUserHomeDirectory: URL {
        do {
            return try resolvedLoginUserHomeDirectory(
                forUserID: getuid(),
                lookingUpHomeDirectory: { userID in
                    try posixLoginHomeDirectory(forUserID: userID)
                }
            )
        } catch {
            preconditionFailure(
                "Unable to determine the login user's POSIX home directory: " +
                    error.localizedDescription
            )
        }
    }
}

struct POSIXHomeDirectoryLookupResult {
    let status: Int32
    let homeDirectoryPath: String?
}

enum LoginHomeDirectoryError: Error, Equatable, LocalizedError {
    case invalidPath(String)
    case lookupFailed(Int32)
    case missingAccount(uid_t)

    var errorDescription: String? {
        switch self {
        case let .invalidPath(path):
            "Invalid POSIX home directory: \(path)"
        case let .lookupFailed(code):
            "POSIX account lookup failed with code \(code)."
        case let .missingAccount(userID):
            "No POSIX account record exists for user ID \(userID)."
        }
    }
}
