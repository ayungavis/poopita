import Foundation
import Testing

private let todayFolder = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appending(path: "Sources/PoopitaKit/Features/Today")

struct TodayNavigationBarTests {
    @Test func todayDrawsItsTopBarOutsideTheNavigationBar() throws {
        let manager = FileManager.default
        let files = try #require(manager.enumerator(atPath: todayFolder.path()))
            .compactMap { $0 as? String }
            .filter { $0.hasSuffix(".swift") }
        #expect(!files.isEmpty)
        for file in files {
            let source = try String(contentsOf: todayFolder.appending(path: file), encoding: .utf8)
            #expect(!source.contains("ToolbarItem("), "\(file) puts an item in the navigation bar")
        }
    }
}
