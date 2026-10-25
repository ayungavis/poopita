import Foundation
import Sentry

public enum SentryPrivacy {
    public static func options(dsn: String, environment: String, cacheDirectory: URL) -> Options {
        let options = Options()
        options.dsn = dsn
        options.environment = environment
        options.cacheDirectoryPath = cacheDirectory.path(percentEncoded: false)
        options.sendDefaultPii = false
        options.enableAutoBreadcrumbTracking = false
        options.enableNetworkBreadcrumbs = false
        options.enableCaptureFailedRequests = false
        options.enableAutoSessionTracking = false
        options.enableAutoPerformanceTracing = false
        options.enableNetworkTracking = false
        options.enableFileIOTracing = false
        options.enableCoreDataTracing = false
        options.enableSwizzling = false
        options.tracesSampleRate = 0
        options.maxAttachmentSize = 0
        options.maxBreadcrumbs = 0
        options.sendClientReports = false
        options.enableMetricKit = false
        options.enableAppHangTracking = false
        #if os(iOS)
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            options.sessionReplay.sessionSampleRate = 0
            options.sessionReplay.onErrorSampleRate = 0
        #endif
        options.beforeSend = { source in
            let sanitized = event(source)
            if ["development", "production", "test"].contains(environment) {
                sanitized.environment = environment
            }
            return sanitized
        }
        return options
    }

    public static func event(_ source: Event) -> Event {
        let result = Event(level: source.level)
        result.eventId = source.eventId
        result.timestamp = source.timestamp
        result.platform = "cocoa"
        result.tags = source.tags?.filter { key, value in
            key == "code" && Log.diagnosticCodes.contains(value)
                || key == "operation" && Log.diagnosticOperations.contains(value)
                || key == "status" && Int(value).map { (100 ... 599).contains($0) } == true
        }
        result.exceptions = source.exceptions?.map { original in
            let exception = Exception(value: "Technical failure", type: "Crash")
            if Log.diagnosticCodes.contains(original.type) {
                exception.type = original.type
            }
            exception.threadId = original.threadId
            exception.stacktrace = original.stacktrace.map(stacktrace)
            let mechanism = Mechanism(type: "generic")
            mechanism.handled = original.mechanism?.handled
            exception.mechanism = mechanism
            return exception
        }
        result.threads = source.threads?.map { original in
            let thread = SentryThread(threadId: original.threadId)
            thread.crashed = original.crashed
            thread.current = original.current
            thread.isMain = original.isMain
            thread.stacktrace = original.stacktrace.map(stacktrace)
            return thread
        }
        result.stacktrace = source.stacktrace.map(stacktrace)
        result.debugMeta = source.debugMeta?.compactMap { original in
            guard let identifier = original.debugID.flatMap(UUID.init(uuidString:)) else { return nil }
            let image = DebugMeta()
            image.type = "macho"
            image.debugID = identifier.uuidString
            image.imageAddress = address(original.imageAddress)
            image.imageVmAddress = address(original.imageVmAddress)
            image.imageSize = original.imageSize
            return image
        }
        return result
    }

    private static func stacktrace(_ original: SentryStacktrace) -> SentryStacktrace {
        let frames = original.frames.map { original in
            let frame = Frame()
            frame.instructionAddress = address(original.instructionAddress)
            frame.symbolAddress = address(original.symbolAddress)
            frame.imageAddress = address(original.imageAddress)
            frame.inApp = original.inApp
            return frame
        }
        return SentryStacktrace(frames: frames, registers: [:])
    }

    private static func address(_ value: String?) -> String? {
        guard let value, value.hasPrefix("0x"), (3 ... 18).contains(value.count),
              value.dropFirst(2).allSatisfy(\.isHexDigit)
        else { return nil }
        return value
    }
}
