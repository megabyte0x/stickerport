import SwiftUI

@main
@MainActor
struct StickerBridgeMacApp: App {
    @State private var store: MacBridgeStore

    init() {
        let store = MacBridgeStore(
            whatsAppPicker: WhatsAppContainerPicker(),
            reader: WhatsAppStickerReader(),
            exportPicker: ExportFolderPicker(),
            exporter: SignalFolderExporter(),
            handoff: SignalHandoffService()
        )

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--design-preview") {
            store.loadDesignPreview(
                sources: StickerDesignPreview.makeSources(),
                selectedStickerIDs: StickerDesignPreview.selectedStickerIDs
            )
        }
        #endif

        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup("StickerPort", id: "main") {
            MacRootView(store: store)
        }
        .defaultSize(width: 920, height: 720)
        .windowResizability(.contentMinSize)
    }
}
