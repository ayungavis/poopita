import Foundation
import Testing

private let colorCatalog = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appending(path: "Sources/DesignSystem/Resources/Colors.xcassets")

private struct ColorSet: Decodable {
    let colors: [ColorEntry]
}

private struct ColorEntry: Decodable {
    let appearances: [ColorAppearance]?
    let color: ColorValue
}

private struct ColorAppearance: Decodable {
    let value: String
}

private struct ColorValue: Decodable {
    let components: ColorComponents
}

private struct ColorComponents: Decodable {
    let red: String, green: String, blue: String
}

private enum Appearance: String, CaseIterable {
    case light, dark
}

private func luminance(_ name: String, _ appearance: Appearance) throws -> Double {
    let data = try Data(contentsOf: colorCatalog.appending(path: "\(name).colorset/Contents.json"))
    let entries = try JSONDecoder().decode(ColorSet.self, from: data).colors
    let entry = try #require(entries.first { ($0.appearances?.first?.value ?? "light") == appearance.rawValue })
    let channels = [entry.color.components.red, entry.color.components.green, entry.color.components.blue]
        .compactMap(Double.init)
        .map { $0 <= 0.039_28 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
    try #require(channels.count == 3)
    return 0.212_6 * channels[0] + 0.715_2 * channels[1] + 0.072_2 * channels[2]
}

private func contrast(_ foreground: String, on background: String, _ appearance: Appearance) throws -> Double {
    let first = try luminance(foreground, appearance)
    let second = try luminance(background, appearance)
    return (max(first, second) + 0.05) / (min(first, second) + 0.05)
}

struct PaletteContrastTests {
    @Test(arguments: [
        ("textPrimary", "background"), ("textPrimary", "surface"), ("textPrimary", "track"), ("textPrimary", "entry"),
        ("textSecondary", "background"), ("textSecondary", "surface"),
        ("accent", "background"), ("accent", "surface"), ("accent", "entry"),
        ("destructive", "background"), ("destructive", "surface"),
        ("onInk", "ink"),
    ])
    func textPairsMeetBodyContrast(foreground: String, background: String) throws {
        for appearance in Appearance.allCases {
            let ratio = try contrast(foreground, on: background, appearance)
            #expect(ratio >= 4.5, "\(foreground) on \(background) (\(appearance)) is \(ratio)")
        }
    }

    @Test(arguments: ["marker"])
    func dayMarkersMeetGraphicContrast(marker: String) throws {
        for appearance in Appearance.allCases {
            let ratio = try contrast(marker, on: "background", appearance)
            #expect(ratio >= 3, "\(marker) on background (\(appearance)) is \(ratio)")
        }
    }

    @Test func switchOnTrackSeparatesFromThumbAndSurface() throws {
        for appearance in Appearance.allCases {
            let track = try luminance("switchOn", appearance)
            let thumbRatio = (1 + 0.05) / (track + 0.05)
            #expect(thumbRatio >= 3, "white thumb on switchOn (\(appearance)) is \(thumbRatio)")
            let surfaceRatio = try contrast("switchOn", on: "surface", appearance)
            #expect(surfaceRatio >= 3, "switchOn on surface (\(appearance)) is \(surfaceRatio)")
        }
    }
}
