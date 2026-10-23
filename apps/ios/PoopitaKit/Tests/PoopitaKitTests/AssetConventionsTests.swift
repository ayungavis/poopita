import Foundation
import Testing

private let sourcesRoot = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appending(path: "Sources")

private func relativePaths(withSuffix suffix: String) -> [String] {
    guard let walker = FileManager.default.enumerator(atPath: sourcesRoot.path()) else { return [] }
    return walker.compactMap { $0 as? String }.filter { $0.hasSuffix(suffix) }
}

private func referencedImages() throws -> Set<String> {
    try Set(relativePaths(withSuffix: ".swift").flatMap { path in
        let source = try String(contentsOf: sourcesRoot.appending(path: path), encoding: .utf8)
        return source.matches(of: /Image\((?:decorative: )?"(\w+)"/).map { String($0.output.1) }
    })
}

private func imageSets() -> Set<String> {
    Set(relativePaths(withSuffix: ".imageset").map {
        String(($0 as NSString).lastPathComponent.dropLast(".imageset".count))
    })
}

struct AssetConventionsTests {
    @Test func everyImageNameHasAnImageSet() throws {
        let missing = try referencedImages().subtracting(imageSets())
        #expect(missing.isEmpty, "Image names with no imageset (render blank at runtime): \(missing.sorted())")
    }

    @Test func everyImageSetIsUsed() throws {
        let unused = try imageSets().subtracting(referencedImages())
        #expect(unused.isEmpty, "Imagesets nothing references: \(unused.sorted())")
    }
}
