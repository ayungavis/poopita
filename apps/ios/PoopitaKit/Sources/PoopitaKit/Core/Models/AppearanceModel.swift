import Observation
import SwiftUI

@MainActor
@Observable
final class AppearanceModel {
    private(set) var theme: AppTheme
    private let repository: any AppearanceRepository

    init(repository: any AppearanceRepository) {
        self.repository = repository
        theme = repository.theme()
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
}
