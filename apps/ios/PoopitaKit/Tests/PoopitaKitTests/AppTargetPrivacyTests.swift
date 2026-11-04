import Foundation
import Testing

private let appTarget = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appending(path: "Poopita")

struct AppTargetPrivacyTests {
    @Test(arguments: ["NSPrivacyCollectedDataTypeCrashData", "NSPrivacyCollectedDataTypeOtherDiagnosticData"])
    func manifestDeclaresDiagnosticsAsUnlinkedAndUntracked(type: String) throws {
        let data = try Data(contentsOf: appTarget.appending(path: "PrivacyInfo.xcprivacy"))
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        let collected = try #require(plist["NSPrivacyCollectedDataTypes"] as? [[String: Any]])
        let entry = try #require(collected.first { $0["NSPrivacyCollectedDataType"] as? String == type })
        #expect(entry["NSPrivacyCollectedDataTypeLinked"] as? Bool == false)
        #expect(entry["NSPrivacyCollectedDataTypeTracking"] as? Bool == false)
        #expect(entry["NSPrivacyCollectedDataTypePurposes"] as? [String] == [
            "NSPrivacyCollectedDataTypePurposeAppFunctionality",
        ])
    }

    @Test(arguments: ["en", "id"])
    func faceIDPurposeIsLocalizedForEveryShippedLanguage(language: String) throws {
        let url = appTarget.appending(path: "\(language).lproj/InfoPlist.strings")
        let strings = try #require(NSDictionary(contentsOf: url) as? [String: String])
        #expect(strings["NSFaceIDUsageDescription"]?.isEmpty == false)
    }
}
