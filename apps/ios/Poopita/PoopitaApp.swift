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

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = Bundle.main
                .object(forInfoDictionaryKey: "SentryEnvironment") as? String ?? "development"
        }
        Log.breadcrumbRecorder = { error, context in
            let crumb = Breadcrumb(level: .warning, category: "http")
            crumb.message = String(describing: error)
            crumb.data = context.fields
            SentrySDK.addBreadcrumb(crumb)
        }
        Log.errorReporter = { error, context in
            SentrySDK.capture(error: error) { scope in
                for (key, value) in context.fields {
                    scope.setTag(value: value, key: key)
                }
            }
        }
    }
}
