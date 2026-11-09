import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var isPresented: Bool
    private(set) var state: OnboardingViewData
    private let repository: any OnboardingRepository
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private var step = OnboardingViewData.Step.welcome

    init(
        repository: any OnboardingRepository, diary: any DiaryRepository,
        now: @escaping () -> Date, timeZone: @escaping () -> TimeZone
    ) {
        self.repository = repository
        self.now = now
        self.timeZone = timeZone
        let isNewDiary = ((try? diary.entries().isEmpty) ?? false) && ((try? diary.checkIns().isEmpty) ?? false)
        isPresented = isNewDiary && !repository.isFinished()
        state = Self.viewData(step: .welcome, now: now(), timeZone: timeZone())
        if !isNewDiary, !repository.isFinished() {
            finish()
        }
    }

    func next() {
        guard let following = OnboardingViewData.Step(rawValue: step.rawValue + 1) else {
            finish()
            return
        }
        step = following
        state = Self.viewData(step: following, now: now(), timeZone: timeZone())
    }

    func finish() {
        do {
            try repository.finish()
        } catch {
            Log.report(error, context: Log.Context(operation: "onboarding.finish"))
        }
        isPresented = false
    }
}

extension OnboardingViewModel {
    static func viewData(step: OnboardingViewData.Step, now: Date, timeZone: TimeZone) -> OnboardingViewData {
        let calendar = TodayViewModel.calendar(timeZone)
        let marks: [DayMarkViewData] = [.logs(1), .logs(2), .noPoop, .unrecorded, .logs(1)]
        var weekday = Date.FormatStyle.dateTime.weekday(.narrow)
        weekday.timeZone = timeZone
        var number = Date.FormatStyle.dateTime.day()
        number.timeZone = timeZone
        let days = marks.enumerated().compactMap { index, mark -> OnboardingDayViewData? in
            guard let date = calendar.date(byAdding: .day, value: index - (marks.count - 1), to: now) else { return nil }
            return OnboardingDayViewData(
                id: String(index), weekdaySymbol: date.formatted(weekday), dayNumber: date.formatted(number),
                mark: mark, isToday: index == marks.count - 1
            )
        }
        let count = OnboardingViewData.Step.allCases.count
        return OnboardingViewData(
            step: step,
            progressLabel: String(localized: "onboarding.progress \(step.rawValue + 1) \(count)", bundle: .module),
            sampleWeek: days
        )
    }
}
