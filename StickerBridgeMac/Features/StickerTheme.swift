import SwiftUI

enum StickerTheme {
    static let coral = Color(
        red: 0.96,
        green: 0.40,
        blue: 0.31
    )
    static let coralDeep = Color(
        red: 0.78,
        green: 0.22,
        blue: 0.18
    )
    static let mint = Color(
        red: 0.48,
        green: 0.80,
        blue: 0.67
    )
    static let indigo = Color(
        red: 0.25,
        green: 0.27,
        blue: 0.61
    )
    static let ink = Color(
        red: 0.13,
        green: 0.14,
        blue: 0.22
    )
    static let mutedInk = Color(
        red: 0.35,
        green: 0.36,
        blue: 0.43
    )
    static let surface = Color.white.opacity(0.82)
    static let elevatedSurface = Color.white.opacity(0.94)
    static let hairline = Color.white.opacity(0.88)

    static let canvas = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.98, blue: 0.94),
            Color(red: 1.00, green: 0.94, blue: 0.91),
            Color(red: 0.94, green: 0.97, blue: 1.00)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct StickerSurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    let cornerRadius: CGFloat
    let shadowRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                reduceTransparency
                    ? StickerTheme.elevatedSurface
                    : StickerTheme.surface,
                in: RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .stroke(StickerTheme.hairline, lineWidth: 1)
            }
            .shadow(
                color: StickerTheme.indigo.opacity(0.10),
                radius: shadowRadius,
                y: shadowRadius * 0.45
            )
    }
}

extension View {
    func stickerSurface(
        cornerRadius: CGFloat = 24,
        shadowRadius: CGFloat = 18
    ) -> some View {
        modifier(
            StickerSurfaceModifier(
                cornerRadius: cornerRadius,
                shadowRadius: shadowRadius
            )
        )
    }
}

struct StickerConfettiBackground: View {
    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    var body: some View {
        GeometryReader { proxy in
            Circle()
                .fill(StickerTheme.coral.opacity(0.13))
                .frame(width: 280, height: 280)
                .blur(radius: reduceTransparency ? 0 : 1)
                .offset(x: -90, y: -115)

            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(StickerTheme.mint.opacity(0.14))
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(18))
                .position(
                    x: proxy.size.width - 35,
                    y: proxy.size.height - 20
                )

            Image(systemName: "sparkle")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(StickerTheme.coral.opacity(0.16))
                .position(
                    x: proxy.size.width - 94,
                    y: 82
                )

            Image(systemName: "heart.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(StickerTheme.mint.opacity(0.20))
                .rotationEffect(.degrees(-12))
                .position(x: 82, y: proxy.size.height - 72)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
