import Foundation
import Observation

@MainActor
@Observable
final class AppLockModel {
    static let gracePeriod: TimeInterval = 60
    static let offerAfterLogs = 3

    private(set) var isEnabled: Bool
    private(set) var isLocked: Bool
    private(set) var isOffering = false
    let isAvailable: Bool
    let methodName: String
    private let repository: any AppLockRepository
    private let diary: any DiaryRepository
    private let biometricService: any BiometricService
    private let now: () -> Date
    private var backgroundedAt: Date?

    init(
        repository: any AppLockRepository, diary: any DiaryRepository, biometricService: any BiometricService,
        now: @escaping () -> Date
    ) {
        self.repository = repository
        self.diary = diary
        self.biometricService = biometricService
        self.now = now
        let isAvailable = biometricService.isAvailable()
        let isEnabled = isAvailable && repository.isEnabled()
        self.isAvailable = isAvailable
        self.isEnabled = isEnabled
        isLocked = isEnabled
        methodName = Self.name(biometricService.method())
    }

    func setEnabled(_ enabled: Bool) async -> Bool {
        guard enabled != isEnabled else { return true }
        let reason = String(localized: enabled ? "settings.appLock.reason" : "settings.appLock.disableReason", bundle: .module)
        guard await biometricService.authenticate(reason: reason) else { return false }
        do {
            try repository.setEnabled(enabled)
        } catch {
            Log.report(error, context: Log.Context(operation: "appLock.write"))
            return false
        }
        isEnabled = enabled
        return true
    }

    func unlock() async {
        let reason = String(localized: "settings.appLock.reason", bundle: .module)
        if await biometricService.authenticate(reason: reason) {
            isLocked = false
        }
    }

    func didEnterBackground() {
        guard isEnabled, !isLocked else { return }
        backgroundedAt = now()
    }

    func willEnterForeground() {
        defer { backgroundedAt = nil }
        guard isEnabled, let backgroundedAt, now().timeIntervalSince(backgroundedAt) >= Self.gracePeriod else { return }
        isLocked = true
    }

    func considerOffer() {
        guard isAvailable, !isEnabled, !isOffering, !repository.wasOffered(),
              ((try? diary.entries().count) ?? 0) >= Self.offerAfterLogs
        else { return }
        do {
            try repository.markOffered()
        } catch {
            Log.report(error, context: Log.Context(operation: "appLock.offer"))
            return
        }
        isOffering = true
    }

    func acceptOffer() async {
        isOffering = false
        _ = await setEnabled(true)
    }

    func declineOffer() {
        isOffering = false
    }

    private static func name(_ method: AppLockMethod) -> String {
        switch method {
        case .faceID: String(localized: "appLock.method.faceID", bundle: .module)
        case .touchID: String(localized: "appLock.method.touchID", bundle: .module)
        case .opticID: String(localized: "appLock.method.opticID", bundle: .module)
        case .passcode: String(localized: "appLock.method.passcode", bundle: .module)
        }
    }
}
