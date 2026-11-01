#if canImport(UIKit)
    import UIKit

    public enum NavigationBarStyle {
        @MainActor
        public static func apply() {
            AppFont.registerFonts()
            let color = UIColor(named: "textPrimary", in: .module, compatibleWith: nil) ?? .label
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.largeTitleTextAttributes = [.font: font(size: 30, style: .largeTitle), .foregroundColor: color]
            appearance.titleTextAttributes = [.font: font(size: 17, style: .headline), .foregroundColor: color]
            let bar = UINavigationBar.appearance()
            bar.standardAppearance = appearance
            bar.compactAppearance = appearance
            bar.scrollEdgeAppearance = appearance
        }

        private static func font(size: CGFloat, style: UIFont.TextStyle) -> UIFont {
            let descriptor = UIFontDescriptor(fontAttributes: [
                .family: "DM Sans",
                .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold],
            ])
            return UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont(descriptor: descriptor, size: size))
        }
    }
#endif
