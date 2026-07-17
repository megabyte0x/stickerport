import SwiftUI

struct MVPExportView: View {
    let model: MVPBridgeModel
    let pack: PreparedPack

    @State private var confirmsRights = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Ready for Signal Desktop") {
                LabeledContent("Pack", value: pack.title)
                LabeledContent("Author", value: pack.author)
                LabeledContent("Stickers", value: "\(pack.stickers.count)")
            }

            Section {
                Toggle(
                    "I own this sticker art or have permission to transfer and share it.",
                    isOn: $confirmsRights
                )
            }

            Section {
                Button("Create Signal Desktop ZIP") {
                    do {
                        exportURL = try SignalDesktopExporter(workspaceRoot: model.workspaceRoot)
                            .export(pack)
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .disabled(!confirmsRights)

                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share or Save ZIP", systemImage: "square.and.arrow.up")
                    }
                    Text("Unzip this file on a linked computer, then use Signal Desktop's Create/Upload Sticker Pack flow.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Export for Signal Desktop")
    }
}
