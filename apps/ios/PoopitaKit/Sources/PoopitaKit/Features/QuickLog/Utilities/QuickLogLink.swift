import Foundation

public enum QuickLogLink {
    static let scheme = "poopita"
    public static let url = URL(string: "poopita://log")! // a fixed literal that always parses

    static func route(for url: URL) -> RemindersRoute? {
        guard url.scheme?.lowercased() == scheme, url.host()?.lowercased() == "log" else { return nil }
        return .log
    }
}
