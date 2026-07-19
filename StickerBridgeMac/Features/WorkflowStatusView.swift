import SwiftUI

struct WorkflowStatusView: View {
    let icon: String
    let title: String
    let message: String
    let showsProgress: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(StickerTheme.coral.opacity(0.13))
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(StickerTheme.coral)
            }

            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(StickerTheme.ink)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(StickerTheme.mutedInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }

            if showsProgress {
                ProgressView()
                    .controlSize(.small)
                    .tint(StickerTheme.coral)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(42)
        .stickerSurface(cornerRadius: 28, shadowRadius: 20)
    }
}

struct WorkflowFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(StickerTheme.coral.opacity(0.13))
                    .frame(width: 88, height: 88)
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(StickerTheme.coral)
            }

            VStack(spacing: 7) {
                Text("That folder didn’t work")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(StickerTheme.ink)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(StickerTheme.mutedInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

            Button("Choose WhatsApp Folder Again", action: retry)
                .buttonStyle(StickerPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(42)
        .stickerSurface(cornerRadius: 28, shadowRadius: 20)
    }
}

struct StickerPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(
                configuration.isPressed
                    ? StickerTheme.coralDeep
                    : StickerTheme.coral,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(
                color: StickerTheme.coral.opacity(
                    configuration.isPressed ? 0.12 : 0.24
                ),
                radius: configuration.isPressed ? 3 : 9,
                y: configuration.isPressed ? 1 : 5
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                reduceMotion
                    ? nil
                    : .spring(response: 0.22, dampingFraction: 0.92),
                value: configuration.isPressed
            )
    }
}
