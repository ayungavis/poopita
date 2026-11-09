import AppIntents
import PoopitaKit

struct LogPoopIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.log.title"
    static let description = IntentDescription("intent.log.description")
    static let supportedModes: IntentModes = .foreground

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(QuickLogLink.url))
    }
}
