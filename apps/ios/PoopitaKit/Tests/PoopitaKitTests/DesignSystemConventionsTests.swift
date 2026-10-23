import Foundation
import Testing

private let designSystem = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appending(path: "Sources/DesignSystem")

private func referencedColors() throws -> Set<String> {
    let theme = try String(contentsOf: designSystem.appending(path: "Theme.swift"), encoding: .utf8)
    return Set(theme.matches(of: /Color\("(\w+)"/).map { String($0.output.1) })
}

private func colorSets() throws -> Set<String> {
    let catalog = designSystem.appending(path: "Resources/Colors.xcassets")
    let entries = try FileManager.default.contentsOfDirectory(atPath: catalog.path())
    return Set(entries.filter { $0.hasSuffix(".colorset") }.map { String($0.dropLast(".colorset".count)) })
}

struct DesignSystemConventionsTests {
    @Test func everyAppColorHasAColorSet() throws {
        let missing = try referencedColors().subtracting(colorSets())
        #expect(missing.isEmpty, "AppColor names with no colorset (renders clear at runtime): \(missing.sorted())")
    }

    @Test func everyColorSetIsExposedThroughAppColor() throws {
        let orphans = try colorSets().subtracting(referencedColors())
        #expect(orphans.isEmpty, "Colorsets no AppColor exposes: \(orphans.sorted())")
    }
}
