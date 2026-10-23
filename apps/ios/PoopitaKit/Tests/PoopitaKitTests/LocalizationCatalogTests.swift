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
}
