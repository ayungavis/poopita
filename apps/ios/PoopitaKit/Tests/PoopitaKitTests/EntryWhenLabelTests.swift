import Foundation
@testable import PoopitaKit
import Testing

@MainActor
struct EntryWhenLabelTests {
    private static let zone = TimeZone(identifier: "Asia/Jakarta") ?? .gmt
    private static let locale = Locale(identifier: "en_US")
    private static let now = Date(timeIntervalSince1970: 1_793_511_000)

    private static func label(hoursAgo: Double) -> (date: String, time: String) {
        EntryEditorViewModel.whenLabels(
            for: now.addingTimeInterval(-hoursAgo * 3600), now: now, timeZone: zone, locale: locale
        )
    }

    @Test func namesTodayAndYesterdayAndShowsOlderDays() {
        #expect(Self.label(hoursAgo: 0).date == String(localized: "diary.today", bundle: .module))
        #expect(Self.label(hoursAgo: 24).date == String(localized: "entry.yesterday", bundle: .module))
        #expect(Self.label(hoursAgo: 72).date == "Thu, Oct 29")
    }

    @Test func showsTimeInTheEntryTimeZone() {
        #expect(Self.label(hoursAgo: 0).time.replacing("\u{202F}", with: " ") == "12:30 PM")
    }
}
