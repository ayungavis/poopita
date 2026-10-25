import Foundation
@testable import PoopitaKit
import Sentry
import Testing

struct DiagnosticPrivacyTests {
    @Test func disablesAutomaticSensitiveCaptureAndUsesTheSanitizer() throws {
        let options = SentryPrivacy.options(
            dsn: "https://public@example.invalid/1", environment: "test",
            cacheDirectory: URL(filePath: "/tmp/poopita diagnostics")
        )
        #expect(options.cacheDirectoryPath == "/tmp/poopita diagnostics")
        #expect(!options.sendDefaultPii)
        #expect(!options.enableAutoBreadcrumbTracking)
        #expect(!options.enableNetworkBreadcrumbs)
        #expect(!options.enableCaptureFailedRequests)
        #expect(!options.enableAutoSessionTracking)
        #expect(!options.enableAutoPerformanceTracing)
        #expect(options.tracesSampleRate == 0)
        #expect(options.maxAttachmentSize == 0)
        #expect(!options.enableSwizzling)
        #expect(options.enableCrashHandler)
        let callback = try #require(options.beforeSend)
        let event = Event(level: .error)
        event.extra = ["note": "secret"]
        #expect(callback(event)?.extra == nil)
    }

    #if os(macOS)
        @MainActor
        @Test func sdkEnvelopeContainsNoSensitiveTextAfterScopeAndSDKProcessing() throws {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + " diagnostics")
            let server = StubServer()
            defer {
                SentrySDK.close()
                server.session.invalidateAndCancel()
                do {
                    try FileManager.default.removeItem(at: directory)
                } catch {
                    Issue.record(error)
                }
            }
            try ProtectedStorage.prepare(directory)
            let options = SentryPrivacy.options(
                dsn: "https://public@example.invalid/1", environment: "test", cacheDirectory: directory
            )
            options.enableCrashHandler = false
            options.urlSession = server.session
            server.stub("/api/1/envelope/", .json("{}"))
            SentrySDK.start(options: options)
            let secret = "private-note-and-recovery-key"
            SentrySDK.configureScope { scope in
                scope.setExtra(value: secret, key: "diary")
                scope.setTag(value: secret, key: "credential")
            }
            let event = Event(level: .error)
            event.exceptions = [Exception(value: secret, type: secret)]
            let identifier = SentrySDK.capture(event: event)
            #expect(identifier != SentryId.empty)
            SentrySDK.flush(timeout: 5)
            let request = try #require(server.sent(to: "/api/1/envelope/").first)
            let body = try Self.envelopeData(request.body)
            let payload = try #require(String(data: body, encoding: .utf8))
            #expect(payload.contains("Technical failure"))
            #expect(!payload.contains(secret))
        }

        private static func envelopeData(_ data: Data) throws -> Data {
            guard data.starts(with: [0x1F, 0x8B]) else { return data }
            let process = Process()
            process.executableURL = URL(filePath: "/usr/bin/gzip")
            process.arguments = ["-dc"]
            let input = Pipe()
            let output = Pipe()
            process.standardInput = input
            process.standardOutput = output
            try process.run()
            try input.fileHandleForWriting.write(contentsOf: data)
            try input.fileHandleForWriting.close()
            let result = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw CocoaError(.fileReadCorruptFile) }
            return result
        }
    #endif

    @Test func removesSensitiveFieldsWithoutMutatingTheOriginalEvent() throws {
        let secret = "private-note-and-recovery-key"
        let event = Event(level: .fatal)
        event.message = SentryMessage(formatted: secret)
        event.extra = ["note": secret]
        event.tags = ["key": secret]
        event.context = ["diary": ["note": secret]]
        let exception = Exception(value: secret, type: secret)
        let frame = Frame()
        frame.instructionAddress = "0x1234"
        frame.imageAddress = "0x1000"
        frame.function = secret
        frame.fileName = secret
        frame.vars = ["note": secret]
        frame.contextLine = secret
        exception.stacktrace = SentryStacktrace(frames: [frame], registers: ["x0": secret])
        event.exceptions = [exception]

        let sanitized = SentryPrivacy.event(event)
        let encoded = try JSONSerialization.data(withJSONObject: sanitized.serialize(), options: [.sortedKeys])
        let payload = try #require(String(data: encoded, encoding: .utf8))
        #expect(!payload.contains(secret))
        #expect(payload.contains("0x1234"))
        #expect(sanitized.level == .fatal)
        #expect(exception.value == secret)
        #expect(frame.vars?["note"] as? String == secret)
    }

    @Test func diagnosticsDiscardUntrustedContextAndErrorText() {
        let secret = "private-note-and-recovery-key"
        let context = Log.Context(operation: secret, endpoint: secret, requestID: secret, status: 503)
        let failure = NSError(domain: secret, code: 7, userInfo: [NSLocalizedDescriptionKey: secret])
        let diagnostic = Log.diagnostic(failure, context: context)
        #expect(diagnostic.code == "unexpected")
        #expect(diagnostic.fields == ["status": "503"])
    }
}
