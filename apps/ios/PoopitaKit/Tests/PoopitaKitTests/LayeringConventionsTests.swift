import Foundation
import Testing

private let sourcesRoot = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appending(path: "Sources/PoopitaKit")

private struct LayerFile {
    let path: String
    let lines: [String]
}

private func files() throws -> [LayerFile] {
    guard let walker = FileManager.default.enumerator(atPath: sourcesRoot.path()) else { return [] }
    return try walker.compactMap { entry -> LayerFile? in
        guard let relative = entry as? String, relative.hasSuffix(".swift") else { return nil }
        let source = try String(contentsOf: sourcesRoot.appending(path: relative), encoding: .utf8)
        return LayerFile(path: relative, lines: source.components(separatedBy: "\n"))
    }
}

private func declaredTypes(in file: LayerFile) -> [String] {
    file.lines.compactMap { line in
        var words = line.split(whereSeparator: \.isWhitespace).map(String.init)
        while let first = words.first, ["public", "internal", "final"].contains(first) {
            words.removeFirst()
        }
        guard words.count >= 2, ["struct", "enum", "class", "actor"].contains(words[0]) else { return nil }
        return String(words[1].prefix { $0.isLetter || $0.isNumber })
    }
}

private func names(_ name: String, in line: String) -> Bool {
    line.split { !$0.isLetter && !$0.isNumber }.contains { $0 == name }
}

private func domainTypes() throws -> [String] {
    try files().filter { $0.path.contains("/Domains/") }.flatMap(declaredTypes)
}

private func isFeature(_ file: LayerFile, suffix: String) -> Bool {
    file.path.hasPrefix("Features/") && file.path.hasSuffix(suffix)
}

private let networkingTokens = ["APIClient", "Endpoint", "DTO"]

struct LayeringConventionsTests {
    @Test func aViewModelExposesViewDataNeverADomainType() throws {
        let domain = try domainTypes()
        var offenders: [String] = []
        for file in try files() where isFeature(file, suffix: "ViewModel.swift") {
            for (index, line) in file.lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("private "), !trimmed.hasPrefix("init"),
                      trimmed.contains("var ") || trimmed.contains("let ")
                else { continue }
                for type in domain where names(type, in: trimmed) {
                    offenders.append("\(file.path):\(index + 1) exposes \(type)")
                }
            }
        }
        #expect(
            offenders.isEmpty,
            "A ViewModel maps Domain → ViewData; its readable state names no domain type:\n\(offenders.joined(separator: "\n"))"
        )
    }

    @Test func aViewNamesNoDomainRepositoryOrNetworkingType() throws {
        let domain = try domainTypes()
        let layerWords = networkingTokens + ["Repository"]
        var offenders: [String] = []
        for file in try files() where isFeature(file, suffix: "View.swift") {
            for (index, line) in file.lines.enumerated() {
                for type in domain where names(type, in: line) {
                    offenders.append("\(file.path):\(index + 1) names \(type)")
                }
                for word in layerWords where line.contains(word) {
                    offenders.append("\(file.path):\(index + 1) names \(word)")
                }
            }
        }
        #expect(
            offenders.isEmpty,
            "A View sees only its injected ViewModel and ViewData:\n\(offenders.joined(separator: "\n"))"
        )
    }

    @Test func aViewModelNeverReachesPastItsRepository() throws {
        var offenders: [String] = []
        for file in try files() where isFeature(file, suffix: "ViewModel.swift") {
            for (index, line) in file.lines.enumerated() {
                for token in networkingTokens where line.contains(token) {
                    offenders.append("\(file.path):\(index + 1) names \(token)")
                }
            }
        }
        #expect(
            offenders.isEmpty,
            "A ViewModel talks to a Repository; DTOs and networking stay below it:\n\(offenders.joined(separator: "\n"))"
        )
    }
}
