import CoreText
import SwiftUI

public enum AppFont {
    public static let largeTitle = Font.custom(sans, size: 30, relativeTo: .largeTitle).weight(.semibold)
    public static let title = Font.custom(sans, size: 22, relativeTo: .title2).weight(.semibold)
    public static let body = Font.custom(sans, size: 16, relativeTo: .body)
    public static let caption = Font.custom(sans, size: 13, relativeTo: .footnote)
    public static let display = Font.custom(sans, size: 48, relativeTo: .largeTitle).weight(.medium)
    public static let wordmark = Font.custom(sans, size: 30, relativeTo: .title).weight(.bold)

    private static let sans = "DM Sans"

    private static let registration: Void = {
        let urls = ["Fonts", nil].flatMap { Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: $0) ?? [] }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    public static func registerFonts() {
        registration
    }
}
