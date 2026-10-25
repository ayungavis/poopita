import PoopitaKit
import Sentry
import SwiftUI

@main
struct PoopitaApp: App {
    private let container = AppContainer()

    init() {
        Self.startSentryIfConfigured()
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }

    private static func startSentryIfConfigured() {
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String,
              let url = URL(string: dsn), url.host()?.isEmpty == false
        else {
            Log.app.info("Sentry disabled: no usable DSN configured")
            return
        }

        do {
            let cache = try ProtectedStorage.directory(named: "Diagnostics")
            try ProtectedStorage.prepare(cache)
            let environment = Bundle.main.object(forInfoDictionaryKey: "SentryEnvironment") as? String ?? "development"
            SentrySDK.start(options: SentryPrivacy.options(dsn: dsn, environment: environment, cacheDirectory: cache))
        } catch {
            Log.report(AppError.storageUnavailable)
            return
        }
        Log.errorReporter = { diagnostic in
            let event = Event(level: .error)
            event.exceptions = [Exception(value: "Technical failure", type: diagnostic.code)]
            event.tags = diagnostic.fields.merging(["code": diagnostic.code]) { _, value in value }
            SentrySDK.capture(event: event)
        }
    }
}
