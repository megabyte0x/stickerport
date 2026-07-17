import SwiftUI

struct ImportView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Prepare for Signal")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("StickerBridge cannot read WhatsApp’s private library. Choose or share files you have permission to use.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Import sticker files") {}
                .buttonStyle(.borderedProminent)
                .disabled(true)
        }
        .padding()
    }
}
