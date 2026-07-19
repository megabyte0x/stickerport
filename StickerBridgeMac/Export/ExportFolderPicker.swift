import AppKit
import Foundation

@MainActor
protocol ExportFolderPicking {
    func chooseExportParent() -> URL?
}

@MainActor
struct ExportFolderPicker: ExportFolderPicking {
    func chooseExportParent() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose Signal Export Location"
        panel.message = "StickerPort creates a new Signal-ready folder here."
        panel.prompt = "Choose Location"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first
        return panel.runModal() == .OK ? panel.url : nil
    }
}
