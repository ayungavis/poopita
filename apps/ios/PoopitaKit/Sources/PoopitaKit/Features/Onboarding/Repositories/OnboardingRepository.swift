import Foundation

@MainActor
protocol OnboardingRepository {
    func isFinished() -> Bool
    func finish() throws
}

@MainActor
final class LocalOnboardingRepository: OnboardingRepository {
    static let finishedKey = "onboarding.finished"
    private let store: any ValueStore

    init(store: any ValueStore) {
        self.store = store
    }

    func isFinished() -> Bool {
        do {
            return try store.read(Bool.self, key: Self.finishedKey) ?? false
        } catch {
            Log.report(error, context: Log.Context(operation: "onboarding.read"))
            return true
        }
    }

    func finish() throws {
        try store.write(true, key: Self.finishedKey)
    }
}
