import CoreTransferable
import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let poopitaBackup = UTType(exportedAs: "com.ayungavis.poopita.backup", conformingTo: .data)
}

struct BackupViewData: Equatable, Sendable {
    let status: String
    let hasRecoveryKey: Bool
}

struct RecoveryKeySetupViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let groups: [String]
    let shareText: String
    let confirmPrompt: String
    let errorMessage: String?
}

struct RecoveryKeyDisplayViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let groups: [String]
    let shareText: String
}

struct RestoreViewData: Identifiable, Equatable, Sendable {
    enum Step: Equatable, Sendable {
        case enterKey(errorMessage: String?)
        case preview(RestorePreviewViewData)
    }

    let id: UUID
    let step: Step
}

struct RestorePreviewViewData: Equatable, Sendable {
    let createdAt: String
    let logsToAdd: String
    let checkInsToAdd: String
    let alreadyHere: String
    let errorMessage: String?
}

struct BackupFileViewData: Transferable, Equatable, Sendable {
    let data: Data
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .poopitaBackup) { $0.data }
            .suggestedFileName(\.fileName)
    }
}
