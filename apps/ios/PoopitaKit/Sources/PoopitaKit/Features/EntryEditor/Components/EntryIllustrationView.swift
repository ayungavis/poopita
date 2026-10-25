import DesignSystem
import SwiftUI

struct EntryIllustrationView: View {
    enum Kind: Equatable, Sendable {
        case type1
        case type2
        case type3
        case type4
        case type5
        case type6
        case type7
        case amount1
        case amount2
        case amount3
        case amount4
        case amount5
    }

    let kind: Kind

    var body: some View {
        image.renderingMode(.original).resizable().scaledToFit()
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
