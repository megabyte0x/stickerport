import AppKit
import Foundation

@MainActor
protocol SignalHandoffOpening {
    func reveal(_ url: URL)
    func openSignalDesktop() -> Bool
}

@MainActor
struct SignalHandoffService: SignalHandoffOpening {
    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openSignalDesktop() -> Bool {
        guard let url = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "org.whispersystems.signal-desktop"
        ) else {
            return false
        }
        NSWorkspace.shared.open(url)
        return true
    }
}
