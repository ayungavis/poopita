import Foundation

struct InsightsBaseline {
    let days: [DiaryDay]
    let logs: [DiaryEntry]
    let counts: [Int]

    init?(_ context: InsightsContext) {
        let recorded: [DiaryDay]
        switch context.source.period {
        case .week:
            recorded = Array(Self.recordedDays(before: context, limit: 180).prefix(28))
        case .month:
            guard let start = context.calendar.date(byAdding: .month, value: -3, to: context.interval.start) else { return nil }
            recorded = Self.recordedDays(before: context, limit: 93).filter { context.date($0) >= start }
        case .year:
            return nil
        }
        guard recorded.count >= 14 else { return nil }
        days = recorded
        logs = recorded.flatMap { context.marks.logs[$0] ?? [] }
        counts = recorded.map { context.marks.logs[$0]?.count ?? 0 }
    }

    private static func recordedDays(before context: InsightsContext, limit: Int) -> [DiaryDay] {
        (1 ... limit).compactMap { offset -> DiaryDay? in
            guard let date = context.calendar.date(byAdding: .day, value: -offset, to: context.interval.start),
                  let day = try? DiaryDay(date: date, timeZone: context.calendar.timeZone)
            else { return nil }
            return InsightsStats.isRecorded(context.marks.mark(day)) ? day : nil
        }
    }
}

enum InsightsStats {
    static func isRecorded(_ mark: DayMarkViewData) -> Bool {
        switch mark {
        case .logs, .noPoop: true
        default: false
        }
    }

    static func range(_ values: [Int]) -> ClosedRange<Int>? {
        let sorted = values.sorted()
        guard let first = sorted.first else { return nil }
        let lower = sorted[(sorted.count - 1) / 4]
        let upper = sorted[(sorted.count - 1) * 3 / 4]
        return max(first, lower) ... max(lower, upper)
    }

    static func median(_ values: [Int]) -> Int? {
        let sorted = values.sorted()
        return sorted.isEmpty ? nil : sorted[sorted.count / 2]
    }

    static func mode<Value: Hashable & Comparable>(_ values: [Value]) -> Value? {
        Dictionary(grouping: values) { $0 }.max { ($0.value.count, $1.key) < ($1.value.count, $0.key) }?.key
    }

    static func share(_ logs: [DiaryEntry], where matches: (Int) -> Bool) -> Double {
        let types = logs.compactMap(\.stoolType)
        return types.isEmpty ? 0 : Double(types.count(where: matches)) / Double(types.count)
    }
}
