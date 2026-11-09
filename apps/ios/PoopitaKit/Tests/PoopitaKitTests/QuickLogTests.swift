import Foundation
@testable import PoopitaKit
import Testing

struct QuickLogLinkTests {
    @Test(arguments: ["poopita://log", "POOPITA://LOG", "poopita://log?from=widget"])
    func theLogLinkOpensTheLogSheet(link: String) throws {
        #expect(try QuickLogLink.route(for: #require(URL(string: link))) == .log)
    }

    @Test(arguments: ["poopita://insights", "https://poopita.ayungavis.com/log", "other://log"])
    func otherLinksAreIgnored(link: String) throws {
        #expect(try QuickLogLink.route(for: #require(URL(string: link))) == nil)
    }

    @Test func theSharedLinkIsTheLogLink() {
        #expect(QuickLogLink.route(for: QuickLogLink.url) == .log)
    }
}

@MainActor
struct RepeatLastLogTests {
    private let now = Date(timeIntervalSince1970: 1_793_000_000)

    private func model(saving entries: [DiaryEntry], editing id: UUID = UUID()) throws -> EntryEditorViewModel {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        try entries.forEach { try repository.save($0) }
        let draft = EntryEditorViewData(occurrenceDate: now, timeZoneIdentifier: "GMT", note: "")
        return try EntryEditorViewModel(repository: repository, entryID: id, draft: draft, now: { now })
    }

    private func entry(hoursAgo: Double, type: Int?, blood: DiaryEntry.Blood? = DiaryEntry.Blood.none) throws -> DiaryEntry {
        let zone = try #require(TimeZone(secondsFromGMT: 0))
        return try DiaryEntry(
            id: UUID(), occurrence: OccurrenceTime(instant: now.addingTimeInterval(-hoursAgo * 3600), timeZone: zone),
            stoolType: type, amount: .large, effort: .moderate, blood: blood, color: .brown, note: "after coffee"
        )
    }

    @Test func aNewLogCanRepeatTheLatestCompleteLog() throws {
        let older = try entry(hoursAgo: 30, type: 3)
        let latestIncomplete = try entry(hoursAgo: 2, type: nil)
        let latestComplete = try entry(hoursAgo: 6, type: 5)
        let model = try model(saving: [older, latestComplete, latestIncomplete])
        #expect(model.repeatSummary?.contains(String(localized: "entry.type5", bundle: .module)) == true)

        model.repeatLastTime()
        #expect(model.draft.stoolType == 5)
        #expect(model.draft.amount == "large")
        #expect(model.draft.effort == "moderate")
        #expect(model.draft.blood == "none")
        #expect(model.draft.color == nil)
        #expect(model.draft.note.isEmpty)
        #expect(model.repeatSummary == nil)
        #expect(model.save())
    }

    @Test func editingALogNeverOffersToRepeat() throws {
        let saved = try entry(hoursAgo: 6, type: 5)
        let other = try entry(hoursAgo: 30, type: 3)
        #expect(try model(saving: [saved, other], editing: saved.id).repeatSummary == nil)
    }

    @Test func aFirstLogHasNothingToRepeat() throws {
        #expect(try model(saving: []).repeatSummary == nil)
    }
}

struct DoctorGuidanceTests {
    @Test func theGuideNamesTheSignsWorthADoctorsLook() {
        let guide = BristolGuideViewData.standard
        #expect(!guide.doctorTitle.isEmpty)
        #expect(guide.doctorSigns.count == 4)
        #expect(Set(guide.doctorSigns).count == guide.doctorSigns.count)
    }
}
