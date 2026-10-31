import Foundation

enum NoteSuggestions {
    static let limit = 500

    static func contains(_ phrase: String, in note: String) -> Bool {
        parts(of: note).contains { $0.caseInsensitiveCompare(phrase) == .orderedSame }
    }

    static func toggling(_ phrase: String, in note: String) -> String {
        if contains(phrase, in: note) {
            return parts(of: note)
                .filter { $0.caseInsensitiveCompare(phrase) != .orderedSame }
                .joined(separator: ", ")
        }
        let existing = parts(of: note)
        let added = existing.isEmpty ? phrase : (existing + [phrase.lowercased()]).joined(separator: ", ")
        return added.count <= limit ? added : note
    }

    private static func parts(of note: String) -> [String] {
        note.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
