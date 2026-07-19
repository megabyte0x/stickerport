import AppKit
import SwiftUI

struct StickerPortHeader: View {
    var body: some View {
        HStack(spacing: 18) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Bring your favorite stickers along")
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .tracking(-0.6)
                    .foregroundStyle(StickerTheme.ink)
                    .accessibilityIdentifier("StickerPort Header")

                Text("Pick what you love, then make a Signal-ready folder.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(StickerTheme.mutedInk)

                HStack(spacing: 8) {
                    PrivacyChip(
                        title: "On-device",
                        systemImage: "lock.fill",
                        tint: StickerTheme.mint
                    )
                    PrivacyChip(
                        title: "Read-only",
                        systemImage: "eye.fill",
                        tint: StickerTheme.coral
                    )
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .stickerSurface(cornerRadius: 28, shadowRadius: 20)
    }
}

private struct PrivacyChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(StickerTheme.ink.opacity(0.78))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.18), in: Capsule())
    }
}
