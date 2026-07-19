import AVFoundation
import AVKit
import SwiftUI

struct SignalHandoffSheet: View {
    let store: MacBridgeStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            header
            SignalTutorialVideo()
            quickSteps

            if store.signalLaunchFailed {
                Label(
                    "Signal Desktop could not be opened. Make sure it is installed, then try again.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(StickerTheme.coralDeep)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("Signal Launch Error")
            }

            actions
        }
        .padding(24)
        .frame(width: 680)
        .background(StickerTheme.canvas)
        .accessibilityIdentifier("Signal Handoff Tutorial")
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(StickerTheme.mint.opacity(0.24))
                    .frame(width: 48, height: 48)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(StickerTheme.indigo)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Your stickers are ready")
                    .font(
                        .system(
                            size: 22,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(StickerTheme.ink)
                Text(
                    "The exported Stickers folder is open in Finder. Follow this quick guide to add it in Signal."
                )
                .font(.system(size: 13))
                .foregroundStyle(StickerTheme.mutedInk)
            }

            Spacer()
        }
    }

    private var quickSteps: some View {
        HStack(spacing: 8) {
            TutorialStepPill(number: 1, title: "Open creator")
            Image(systemName: "chevron.right")
            TutorialStepPill(number: 2, title: "Select all")
            Image(systemName: "chevron.right")
            TutorialStepPill(number: 3, title: "Add details")
            Image(systemName: "chevron.right")
            TutorialStepPill(number: 4, title: "Upload & install")
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(StickerTheme.mutedInk)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Steps: open the sticker creator, select all exported stickers, add pack details, then upload and install."
        )
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button("Reveal Stickers Again") {
                store.revealStickers()
            }

            Spacer()

            Button("Not Now", role: .cancel) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button("Open Signal Desktop") {
                store.openSignalDesktop()
                if !store.signalLaunchFailed {
                    dismiss()
                }
            }
            .buttonStyle(StickerPrimaryButtonStyle())
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("Open Signal From Tutorial")
        }
    }
}

private struct TutorialStepPill: View {
    let number: Int
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Text("\(number)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(StickerTheme.coral, in: Circle())
            Text(title)
                .lineLimit(1)
        }
    }
}

struct SignalTutorialVideo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var controller = SignalTutorialVideoController()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if controller.isAvailable {
                SignalTutorialPlayerView(player: controller.player)
            } else {
                unavailablePlaceholder
            }

            Button {
                controller.replay()
            } label: {
                Label("Replay", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.ultraThickMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(10)
            .disabled(!controller.isAvailable)
            .accessibilityIdentifier("Replay Signal Tutorial")
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .background(
            StickerTheme.indigo.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(StickerTheme.indigo.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Signal sticker tutorial video")
        .accessibilityIdentifier("Signal Tutorial Video")
        .onAppear {
            if !reduceMotion {
                controller.play()
            }
        }
        .onDisappear {
            controller.pause()
        }
    }

    private var unavailablePlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 34))
                .foregroundStyle(StickerTheme.indigo)
            Text("Signal sticker tutorial")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(StickerTheme.ink)
            Text(
                "In Signal, choose File → Create/Upload Sticker Pack, select every exported sticker, add the pack details, then upload and install."
            )
            .font(.system(size: 12))
            .foregroundStyle(StickerTheme.mutedInk)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 440)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

private struct SignalTutorialPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspect
        playerView.player = player
        playerView.setAccessibilityElement(true)
        playerView.setAccessibilityRole(.image)
        playerView.setAccessibilityLabel(
            "Signal sticker tutorial video"
        )
        playerView.setAccessibilityIdentifier(
            "Signal Tutorial Video"
        )
        return playerView
    }

    func updateNSView(_ playerView: AVPlayerView, context: Context) {
        if playerView.player !== player {
            playerView.player = player
        }
    }

    static func dismantleNSView(
        _ playerView: AVPlayerView,
        coordinator: Void
    ) {
        playerView.player = nil
    }
}

@MainActor
private final class SignalTutorialVideoController {
    let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    let isAvailable: Bool

    init(bundle: Bundle = .main) {
        player.isMuted = true

        guard let url = bundle.url(
            forResource: "SignalStickerTutorial",
            withExtension: "mp4"
        ) else {
            isAvailable = false
            return
        }

        isAvailable = true
        looper = AVPlayerLooper(
            player: player,
            templateItem: AVPlayerItem(url: url)
        )
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func replay() {
        player.seek(to: .zero)
        player.play()
    }
}
