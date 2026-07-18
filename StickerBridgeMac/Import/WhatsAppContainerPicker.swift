import AppKit
import Foundation

@MainActor
protocol WhatsAppFolderPicking {
    func chooseWhatsAppFolder() -> URL?
}

@MainActor
struct WhatsAppContainerPicker: WhatsAppFolderPicking {
    func chooseWhatsAppFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose WhatsApp Sticker Data"
        panel.message = "Choose group.net.whatsapp.WhatsApp.shared. StickerBridge reads stickers only and never changes WhatsApp data."
        panel.prompt = "Connect WhatsApp"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Group Containers", isDirectory: true)
            .appendingPathComponent(
                "group.net.whatsapp.WhatsApp.shared",
                isDirectory: true
            )
        return panel.runModal() == .OK ? panel.url : nil
    }
}
