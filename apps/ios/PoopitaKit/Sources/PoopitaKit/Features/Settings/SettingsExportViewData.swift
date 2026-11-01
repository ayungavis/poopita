import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct SettingsExportViewData: Transferable, Equatable, Sendable {
    let fileName: String
    let isPDF: Bool
    let make: @MainActor @Sendable () -> Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { await $0.make() }
            .exportingCondition(\.isPDF)
            .suggestedFileName(\.fileName)
        DataRepresentation(exportedContentType: .commaSeparatedText) { await $0.make() }
            .exportingCondition { !$0.isPDF }
            .suggestedFileName(\.fileName)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.fileName == rhs.fileName && lhs.isPDF == rhs.isPDF
    }
}
