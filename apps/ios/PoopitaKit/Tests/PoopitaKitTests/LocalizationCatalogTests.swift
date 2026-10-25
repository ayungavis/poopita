import Foundation
@testable import PoopitaKit
import Testing

struct LocalizationCatalogTests {
    @Test(arguments: ["en", "id"])
    func theStringCatalogIsCompiledForEveryShippedLanguage(language: String) {
        let compiled = Bundle.module.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: nil,
            localization: language
        )

        #expect(
            compiled != nil,
            """
            Localizable.xcstrings was not compiled for "\(language)", so every String(localized:) \
            returns its key. Run swift test with --build-system swiftbuild (make ios-test does).
            """
        )
    }

    @Test func everyCatalogEntryHasTranslatedEnglishAndIndonesian() throws {
        let catalogURL = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/PoopitaKit/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(json["strings"] as? [String: [String: Any]])
        var offenders: [String] = []
        for (key, entry) in strings where !key.isEmpty {
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            for lang in ["en", "id"] {
                guard let unit = localizations[lang]?["stringUnit"] as? [String: Any],
                      let state = unit["state"] as? String, state == "translated",
                      let value = unit["value"] as? String, !value.isEmpty,
                      value != key || key.hasPrefix("%")
                else {
                    offenders.append("\(key) missing translated \(lang)")
                    continue
                }
            }
        }
        #expect(offenders.isEmpty, "Untranslated keys in Localizable.xcstrings:\n\(offenders.joined(separator: "\n"))")
    }

    @Test func labelsInViewsDoNotBypassModuleBundle() throws {
        let sourcesRoot = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/PoopitaKit")
        guard let walker = FileManager.default.enumerator(atPath: sourcesRoot.path()) else { return }
        var offenders: [String] = []
        for case let relative as String in walker where relative.hasSuffix(".swift") {
            let fileURL = sourcesRoot.appending(path: relative)
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("//") else { continue }
                if line.contains("Label(\"") {
                    offenders.append("\(relative):\(index + 1) uses Label(\"...\") without bundle: .module")
                }
            }
        }
        #expect(offenders.isEmpty, "Labels must use bundle: .module via trailing closure:\n\(offenders.joined(separator: "\n"))")
    }
}
