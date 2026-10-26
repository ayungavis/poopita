import Foundation

extension PatternsViewModel {
    static func timeOfDay(for entries: [DiaryEntry]) -> PatternsTimeOfDaySectionViewData {
        let periods: [PatternsTimePeriod] = [.morning, .afternoon, .evening, .night]
        let total = Double(entries.count)
        let items = periods.map { period -> PatternsPeriodViewData in
            let count = entries.filter { entry in
                let hour = entry.occurrence.hour
                return switch period {
                case .morning: hour >= 5 && hour < 12
                case .afternoon: hour >= 12 && hour < 17
                case .evening: hour >= 17 && hour < 22
                case .night: hour < 5 || hour >= 22
                }
            }.count
            let key = switch period {
            case .morning: "patterns.timeOfDay.morning"
            case .afternoon: "patterns.timeOfDay.afternoon"
            case .evening: "patterns.timeOfDay.evening"
            case .night: "patterns.timeOfDay.night"
            }
            let title = String(localized: String.LocalizationValue(key), bundle: .module)
            return PatternsPeriodViewData(
                period: period, title: title, count: count,
                ratio: total > 0 ? Double(count) / total : 0
            )
        }
        return PatternsTimeOfDaySectionViewData(
            periods: entries.isEmpty ? [] : items,
            totalEntries: entries.count,
            hasEntries: !entries.isEmpty
        )
    }

    static func observationSection(
        choices: [EntryChoiceViewData], values: [String], totalEntries: Int
    ) -> PatternsObservationSectionViewData {
        let counts = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
        let items = choices.map { choice in
            let count = counts[choice.id] ?? 0
            let ratio = values.isEmpty ? 0 : Double(count) / Double(values.count)
            return PatternsObservationItemViewData(
                id: choice.id, title: choice.title, count: count, ratio: ratio,
                percentageLabel: ratio.formatted(.percent.precision(.fractionLength(0)))
            )
        }
        return PatternsObservationSectionViewData(
            items: items, recordedCount: values.count, totalEntries: totalEntries, missingCount: totalEntries - values.count
        )
    }

    static func consistency(for entries: [DiaryEntry]) -> PatternsConsistencySectionViewData {
        let classified = entries.filter { $0.stoolType != nil }
        let total = Double(classified.count)
        let items = (1 ... 7).map { type in
            let count = classified.filter { $0.stoolType == type }.count
            return PatternsConsistencyItemViewData(
                type: type, title: String(localized: "patterns.consistency.type \(type)", bundle: .module),
                count: count, ratio: total > 0 ? Double(count) / total : 0
            )
        }
        let ratio = String(
            localized: "patterns.consistency.classifiedRatio \(classified.count), \(entries.count)",
            bundle: .module
        )
        return PatternsConsistencySectionViewData(
            items: items, totalClassified: classified.count, totalEntries: entries.count,
            hasEntries: !classified.isEmpty,
            ratioLabel: classified.isEmpty ? String(localized: "patterns.consistency.noneClassified", bundle: .module) : ratio
        )
    }
}
