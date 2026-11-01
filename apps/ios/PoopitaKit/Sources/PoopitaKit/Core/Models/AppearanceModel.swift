import Observation
import SwiftUI

@MainActor
@Observable
final class AppearanceModel {
    private(set) var theme: AppTheme
    private(set) var hidesInAppSwitcher: Bool
    private let repository: any AppearanceRepository

    init(repository: any AppearanceRepository) {
        self.repository = repository
        theme = repository.theme()
        hidesInAppSwitcher = repository.hidesInAppSwitcher()
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func setTheme(_ theme: AppTheme) throws {
        guard theme != self.theme else { return }
        try repository.setTheme(theme)
        self.theme = theme
    }

    func setHidesInAppSwitcher(_ hides: Bool) throws {
        guard hides != hidesInAppSwitcher else { return }
        try repository.setHidesInAppSwitcher(hides)
        hidesInAppSwitcher = hides
    }
}
