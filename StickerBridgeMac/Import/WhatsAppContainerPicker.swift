import AppKit
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

    /// Resolves the macOS login account's home, not this app's sandbox Data home.
    private nonisolated static var loginUserHomeDirectory: URL {
        guard let path = NSHomeDirectoryForUser(NSUserName()) else {
            preconditionFailure("Unable to determine the login user's home directory.")
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}
