import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct SettingsExportTests {
    @Test func csvListsEntriesAndCheckInsWithRawValues() throws {
        let entry = try DiaryPersistenceTests.entry(note: "after lunch")
        let checkIn = try NoPoopCheckIn(
            day: DiaryDay(year: 2026, month: 10, day: 30),
            reportedAt: OccurrenceTime(instant: Date(timeIntervalSince1970: 1_793_511_000), timeZone: .gmt),
            coverage: .completed
        )
        let lines = DiaryCSV.make(entries: [entry], checkIns: [checkIn]).split(separator: "\n")
        #expect(lines.first == Substring(DiaryCSV.header))
        #expect(lines[1] == "entry,2026-11-01,05:30,GMT,4,small,easy,none,,,after lunch")
        #expect(lines[2] == "check_in_completed,2026-10-30,,GMT,,,,,,,")
    }

    @Test func csvQuotesSeparatorsAndDefusesFormulas() throws {
        let csv = try DiaryCSV.make(entries: [DiaryPersistenceTests.entry(note: "=SUM(A1), said \"hi\"")], checkIns: [])
        #expect(csv.contains(",\"'=SUM(A1), said \"\"hi\"\"\"\n"))
    }

    @Test func doctorReportNamesEveryRecordedObservation() throws {
        let report = try DiaryReport(entries: [DiaryPersistenceTests.entry(note: "sore")], checkIns: [], now: .now)
        let detail = try #require(report.lines.first?.detail)
        #expect(detail.contains(String(localized: "entry.bloodLabel", bundle: .module)))
        #expect(detail.contains(String(localized: "entry.blood.none", bundle: .module)))
        #expect(detail.contains("sore"))
        #expect(report.summary.contains { $0.contains("1") })

        let empty = DiaryReport(entries: [], checkIns: [], now: .now)
        #expect(empty.lines.map(\.detail) == [String(localized: "settings.report.empty", bundle: .module)])
    }

    @Test func doctorReportPlacesACheckInOnItsOwnDay() throws {
        let entry = try DiaryPersistenceTests.entry(note: "")
        let checkIn = try NoPoopCheckIn(
            day: DiaryDay(year: 2026, month: 10, day: 30),
            reportedAt: OccurrenceTime(instant: Date(timeIntervalSince1970: 1_793_600_000), timeZone: .gmt),
            coverage: .completed
        )
        let report = DiaryReport(entries: [entry], checkIns: [checkIn], now: .now)
        #expect(report.lines.first?.detail == String(localized: "settings.report.checkIn", bundle: .module))
        #expect(report.lines.first?.heading.contains("30") == true)
    }

    @Test func guideCoversAllSevenTypesInThreeGroups() {
        let guide = SettingsViewModel.guide
        #expect(guide.groups.map { $0.rows.map(\.id) } == [["1", "2"], ["3", "4"], ["5", "6", "7"]])
        #expect(guide.groups.flatMap(\.rows).allSatisfy { !$0.description.hasPrefix("settings.") })
    }

    @Test func hidingInTheAppSwitcherDefaultsOnAndCanBeTurnedOff() throws {
        let appearance = try AppearanceTests.model()
        #expect(appearance.hidesInAppSwitcher)
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let model = SettingsViewModel(
            repository: repository, undoModel: UndoModel(repository: repository), appearance: appearance,
            reminderService: TestReminderService(), biometricService: TestBiometricService(),
            languageService: TestLanguageService(), now: { .now }, timeZone: { .gmt }
        )
        #expect(model.state.appearance.hidesInAppSwitcher)

        model.setHidesInAppSwitcher(false)
        #expect(!appearance.hidesInAppSwitcher)
        #expect(!model.state.appearance.hidesInAppSwitcher)
    }
}
