import Foundation

@MainActor
protocol LanguageService {
    var availableCodes: [String] { get }
    var activeCode: String { get }
    var chosenCode: String { get }
    func relaunch(in code: String)
}

@MainActor
final class AppleLanguagesService: LanguageService {
    private static let key = "AppleLanguages"
    private let defaults: UserDefaults
    private let bundle: Bundle

    init(defaults: UserDefaults = .standard, bundle: Bundle = .module) {
        self.defaults = defaults
        self.bundle = bundle
    }

    var availableCodes: [String] {
        bundle.localizations.filter { $0 != "Base" }.sorted()
    }

    var activeCode: String {
        bundle.preferredLocalizations.first ?? "en"
    }

    var chosenCode: String {
        let preferred = defaults.stringArray(forKey: Self.key)?.first
            .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
        guard let preferred, availableCodes.contains(preferred) else { return activeCode }
        return preferred
    }

    func relaunch(in code: String) {
        defaults.set([code], forKey: Self.key)
        defaults.synchronize()
        exit(0)
    }
}
