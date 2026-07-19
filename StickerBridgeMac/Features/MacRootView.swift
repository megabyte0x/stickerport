import SwiftUI

struct MacRootView: View {
    let store: MacBridgeStore

    @State private var showingSignalPrompt = false

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    private var showsSignalTutorialOnLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains(
            "--signal-tutorial-preview"
        )
    }

    private var isHostedUnitTesting: Bool {
        ProcessInfo.processInfo.environment[
            "XCTestConfigurationFilePath"
        ] != nil
    }

    var body: some View {
        ZStack {
            StickerTheme.canvas
                .ignoresSafeArea()
            StickerConfettiBackground()

            VStack(spacing: 18) {
                StickerPortHeader()
                content
            }
            .padding(24)
        }
        .frame(minWidth: 760, minHeight: 640)
        .preferredColorScheme(.light)
        .task {
            if showsSignalTutorialOnLaunch {
                showingSignalPrompt = true
            }
            guard !isUITesting,
                  !isHostedUnitTesting,
                  store.phase == .disconnected else {
                return
            }
            await store.connect()
        }
        .onChange(of: store.phase) { _, newPhase in
            if newPhase == .finished {
                showingSignalPrompt = true
            }
        }
        .sheet(isPresented: $showingSignalPrompt) {
            SignalHandoffSheet(store: store)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .disconnected:
            WorkflowStatusView(
                icon: "sparkles",
                title: "Preparing your sticker shelf",
                message: "Choose WhatsApp’s shared folder when prompted. StickerPort only reads your stickers.",
                showsProgress: true
            )

        case .loading:
            WorkflowStatusView(
                icon: "tray.full.fill",
                title: "Gathering your stickers",
                message: "Reading locally installed packs and Favorites. Nothing leaves this Mac.",
                showsProgress: true
            )

        case .ready, .exporting, .finished:
            StickerCatalogView(store: store)

        case .failed(let message):
            WorkflowFailureView(message: message) {
                Task {
                    store.startOver()
                    await store.connect()
                }
            }
        }
    }
}
