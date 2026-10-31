import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct EntryRequiredFieldsTests {
    private static let instant = Date(timeIntervalSince1970: 1_793_511_000)

    private static func makeModel(_ directory: URL) throws -> (EntryEditorViewModel, LocalDiaryRepository) {
        let repository = try LocalDiaryRepository(store: SwiftDataValueStore(directory: directory))
        let draft = EntryEditorViewData(occurrenceDate: instant, timeZoneIdentifier: "GMT", note: "")
        let model = try EntryEditorViewModel(repository: repository, entryID: UUID(), draft: draft, now: { instant })
        return (model, repository)
    }

    @Test func savingWithoutRequiredObservationsWritesNothingAndNamesEachField() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let (model, repository) = try Self.makeModel(directory)
        #expect(model.missingFields.isEmpty)

        #expect(!model.save())

        #expect(model.missingFields == [.type, .amount, .effort, .blood])
        #expect(model.missingSummary != nil)
        #expect(try repository.entries().isEmpty)
    }

    @Test func pickingAFieldClearsOnlyItsError() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let (model, _) = try Self.makeModel(directory)
        model.save()

        model.selectType("4")
        model.setEffort("easy")

        #expect(model.missingFields == [.amount, .blood])
    }

    @Test func savesEveryObservationOnceRequiredFieldsArePicked() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let (model, repository) = try Self.makeModel(directory)
        model.selectType("4")
        model.setAmount("medium")
        model.setEffort("easy")
        model.setBlood("none")
        model.setColor("brown")
        model.setDuration("twoToFive")

        #expect(model.save())

        let saved = try #require(try repository.entries().first)
        #expect(saved.stoolType == 4)
        #expect(saved.amount == .medium)
        #expect(saved.blood == DiaryEntry.Blood.none)
        #expect(saved.color == .brown)
        #expect(saved.duration == .twoToFive)
        #expect(model.missingFields.isEmpty)
    }

    @Test func tappingTheSelectedOptionAgainClearsIt() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { DiaryPersistenceTests.removeFixture(directory) }
        let (model, _) = try Self.makeModel(directory)
        model.setAmount("small")
        model.setAmount("small")
        model.selectType("2")
        model.selectType("2")

        #expect(model.draft.amount == nil)
        #expect(model.draft.stoolType == nil)
    }

    @Test func logsSavedBeforeTheNewFieldsStillDecode() throws {
        let legacy = """
        {"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","stoolType":3,"amount":"small","effort":"easy","note":"old",
         "occurrence":{"instant":0,"timeZoneIdentifier":"GMT","utcOffsetSeconds":0,
                       "year":2001,"month":1,"day":1,"hour":0,"minute":0}}
        """
        let entry = try JSONDecoder().decode(DiaryEntry.self, from: Data(legacy.utf8))

        #expect(entry.blood == nil)
        #expect(entry.color == nil)
        #expect(entry.duration == nil)
        #expect(entry.stoolType == 3)
    }
}

struct NoteSuggestionsTests {
    @Test func addingAndRemovingAPhraseKeepsTheRestOfTheNote() {
        let first = NoteSuggestions.toggling("Bloating", in: "")
        let second = NoteSuggestions.toggling("Sticky", in: first)

        #expect(first == "Bloating")
        #expect(second == "Bloating, sticky")
        #expect(NoteSuggestions.contains("Sticky", in: second))
        #expect(NoteSuggestions.toggling("Bloating", in: second) == "sticky")
    }

    @Test func aPhraseThatWouldPassTheNoteLimitIsNotAdded() {
        let full = String(repeating: "a", count: NoteSuggestions.limit - 3)

        #expect(NoteSuggestions.toggling("Smelly", in: full) == full)
    }
}

@MainActor
extension EntryEditorViewModel {
    func pickRequiredObservations() {
        if draft.stoolType == nil {
            selectType("4")
        }
        if draft.amount == nil {
            setAmount("small")
        }
        if draft.effort == nil {
            setEffort("easy")
        }
        if draft.blood == nil {
            setBlood("none")
        }
    }
}
