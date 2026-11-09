import DesignSystem
import PoopitaKit
import SwiftUI
import WidgetKit

@main
struct PoopitaWidgetsBundle: WidgetBundle {
    init() {
        AppFont.registerFonts()
    }

    var body: some Widget {
        QuickLogWidget()
        QuickLogControl()
    }
}
