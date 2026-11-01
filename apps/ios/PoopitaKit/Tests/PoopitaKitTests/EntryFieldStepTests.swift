import Foundation
@testable import PoopitaKit
import Testing

struct EntryFieldStepTests {
    private static let empty = EntryEditorViewData(
        occurrenceDate: Date(timeIntervalSince1970: 0), timeZoneIdentifier: "GMT", note: ""
    )

    @Test func pickingAFieldMovesToTheNextEmptyOne() {
        let typed = Self.empty.replacing(\.stoolType, with: 4)
        #expect(EntryFieldStep.next(from: Self.empty, to: typed) == .amount)

        let skipped = typed.replacing(\.effort, with: "easy")
        let amounted = skipped.replacing(\.amount, with: "small")
        #expect(EntryFieldStep.next(from: skipped, to: amounted) == .blood)

        let bled = amounted.replacing(\.blood, with: "none")
        #expect(EntryFieldStep.next(from: amounted, to: bled) == .color)
    }

    @Test func clearingTypingOrAnsweringTheLastFieldDoesNotMove() {
        let typed = Self.empty.replacing(\.stoolType, with: 4)
        #expect(EntryFieldStep.next(from: typed, to: Self.empty) == nil)
        #expect(EntryFieldStep.next(from: typed, to: typed.replacing(\.note, with: "hi")) == nil)

        let full = typed.replacing(\.amount, with: "small").replacing(\.effort, with: "easy")
            .replacing(\.blood, with: "none").replacing(\.color, with: "brown")
        #expect(EntryFieldStep.next(from: full, to: full.replacing(\.duration, with: "underTwo")) == nil)
        #expect(EntryFieldStep.next(from: full, to: full.replacing(\.stoolType, with: 3)) == nil)
    }
}
