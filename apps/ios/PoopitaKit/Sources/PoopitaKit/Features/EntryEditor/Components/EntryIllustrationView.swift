import DesignSystem
import SwiftUI

struct EntryIllustrationView: View {
    let kind: EntryIllustrationKind

    var body: some View {
        image.renderingMode(.template).resizable().scaledToFit()
            .frame(width: Spacing.illustrationWidth, height: Spacing.illustrationHeight)
            .accessibilityHidden(true)
    }

    private var image: Image {
        switch kind {
        case .type1: Image("stoolType1", bundle: .module)
        case .type2: Image("stoolType2", bundle: .module)
        case .type3: Image("stoolType3", bundle: .module)
        case .type4: Image("stoolType4", bundle: .module)
        case .type5: Image("stoolType5", bundle: .module)
        case .type6: Image("stoolType6", bundle: .module)
        case .type7: Image("stoolType7", bundle: .module)
        case .amount1: Image("stoolAmount1", bundle: .module)
        case .amount2: Image("stoolAmount2", bundle: .module)
        case .amount3: Image("stoolAmount3", bundle: .module)
        case .amount4: Image("stoolAmount4", bundle: .module)
        case .amount5: Image("stoolAmount5", bundle: .module)
        }
    }
}
