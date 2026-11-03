import Foundation

struct OnboardingViewData: Equatable, Sendable {
    enum Step: Int, CaseIterable, Sendable {
        case welcome, marks, reminder
    }

    let step: Step
    let progressLabel: String
    let sampleWeek: [OnboardingDayViewData]
}

struct OnboardingDayViewData: Identifiable, Equatable, Sendable {
    let id: String
    let weekdaySymbol: String
    let dayNumber: String
    let mark: DayMarkViewData
    let isToday: Bool
}
