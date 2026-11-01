import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct SettingsDeleteTests {
    @Test func deleteUnlocksOnlyForTheExactWordIgnoringCaseAndSpaces() {
        #expect(SettingsViewModel.confirms("DELETE", word: "DELETE"))
        #expect(SettingsViewModel.confirms("  delete ", word: "DELETE"))
        #expect(SettingsViewModel.confirms("hapus", word: "HAPUS"))
        #expect(!SettingsViewModel.confirms("DELET", word: "DELETE"))
        #expect(!SettingsViewModel.confirms("", word: "DELETE"))
        #expect(!SettingsViewModel.confirms("DELETE ALL", word: "DELETE"))
    }

    @Test func summaryCountsWhatWillGoAndWhenItStarted() throws {
        let entry = try DiaryPersistenceTests.entry(note: "")
        let checkIn = try NoPoopCheckIn(
            day: DiaryDay(year: 2026, month: 10, day: 30),
            reportedAt: OccurrenceTime(instant: Date(timeIntervalSince1970: 1_793_400_000), timeZone: .gmt),
            coverage: .completed
        )
        let data = SettingsViewModel.deleteViewData(entries: [entry, entry], checkIns: [checkIn])
        #expect(data.logs == 2.formatted())
        #expect(data.checkIns == 1.formatted())
        #expect(data.since == Date(timeIntervalSince1970: 1_793_400_000).formatted(.dateTime.day().month(.abbreviated).year()))
        #expect(!data.isEmpty)

        let empty = SettingsViewModel.deleteViewData(entries: [], checkIns: [])
        #expect(empty.isEmpty)
        #expect(empty.since == nil)
    }
}
