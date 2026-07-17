import Foundation
import Observation

@MainActor
@Observable
final class MVPBridgeModel {
    enum Phase: Equatable {
        case idle
        case importing
        case editing
        case preparing
        case ready
        case failed(String)
    }

    var phase: Phase = .idle
    var draft: StickerPackDraft?
    var preparedPack: PreparedPack?

    let workspaceRoot: URL

    init(workspaceRoot: URL? = nil) {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.workspaceRoot = workspaceRoot ?? applicationSupport
            .appendingPathComponent("StickerBridge", isDirectory: true)
            .appendingPathComponent("Workspace", isDirectory: true)
    }

    func importURLs(_ urls: [URL]) async {
        phase = .importing
        do {
            let imported = try await BasicStickerImportService(workspaceRoot: workspaceRoot)
                .importFiles(urls, defaultAuthor: "Me")
            draft = imported
            preparedPack = nil
            phase = .editing
        } catch is CancellationError {
            phase = draft == nil ? .idle : .editing
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func prepare(_ updatedDraft: StickerPackDraft) async {
        draft = updatedDraft
        phase = .preparing
        do {
            preparedPack = try await MVPPreparationService(workspaceRoot: workspaceRoot)
                .prepare(updatedDraft)
            phase = .ready
        } catch is CancellationError {
            phase = .editing
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
