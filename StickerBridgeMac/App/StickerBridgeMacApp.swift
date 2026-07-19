import SwiftUI

@main
@MainActor
struct StickerBridgeMacApp: App {
    @State private var store = MacBridgeStore(
        whatsAppPicker: WhatsAppContainerPicker(),
        reader: WhatsAppStickerReader(),
        exportPicker: ExportFolderPicker(),
        exporter: SignalFolderExporter(),
        handoff: SignalHandoffService()
    )

    var body: some Scene {
        WindowGroup("StickerPort", id: "main") {
            MacRootView(store: store)
        }
        .defaultSize(width: 720, height: 620)
    }
}
