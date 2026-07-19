import AppKit
import SwiftUI

struct StickerTileView: View {
    let sticker: MacWhatsAppSticker
    let isSelected: Bool
    let isDisabled: Bool
    let toggle: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        Button(action: toggle) {
            ZStack(alignment: .topTrailing) {
                thumbnail
                    .frame(maxWidth: .infinity)

                selectionIndicator
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                    ? StickerTheme.coral.opacity(0.12)
                    : StickerTheme.elevatedSurface,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                            ? StickerTheme.coral.opacity(0.72)
                            : StickerTheme.indigo.opacity(0.07),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(
                color: isSelected
                    ? StickerTheme.coral.opacity(0.13)
                    : StickerTheme.indigo.opacity(0.07),
                radius: isSelected ? 8 : 5,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(StickerTileButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.72 : 1)
        .animation(
            reduceMotion
                ? nil
                : .spring(response: 0.32, dampingFraction: 0.90),
            value: isSelected
        )
        .accessibilityIdentifier("Sticker \(sticker.id)")
        .accessibilityLabel("Sticker")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help(isSelected ? "Remove sticker" : "Select sticker")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = NSImage(data: sticker.data) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(height: 68)
                .accessibilityHidden(true)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(StickerTheme.indigo.opacity(0.06))
                    .frame(height: 68)
                Image(systemName: "face.smiling")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(StickerTheme.indigo.opacity(0.55))
            }
            .accessibilityHidden(true)
        }
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(
                    isSelected
                        ? StickerTheme.coral
                        : Color.white.opacity(0.88)
                )
                .frame(width: 23, height: 23)
                .shadow(
                    color: StickerTheme.indigo.opacity(0.12),
                    radius: 3,
                    y: 1
                )

            Image(systemName: isSelected ? "checkmark" : "plus")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(
                    isSelected
                        ? Color.white
                        : StickerTheme.mutedInk
                )
        }
        .scaleEffect(isSelected ? 1 : 0.92)
        .accessibilityHidden(true)
    }
}

private struct StickerTileButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                reduceMotion
                    ? nil
                    : .spring(response: 0.20, dampingFraction: 0.92),
                value: configuration.isPressed
            )
    }
}
