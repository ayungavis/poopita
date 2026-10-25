import Foundation

struct EntryChoiceViewData: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let illustration: EntryIllustrationView.Kind?

    static var types: [Self] {
        [
            Self(
                id: "1",
                title: String(localized: "entry.type1", bundle: .module),
                detail: String(localized: "entry.detail1", bundle: .module),
                illustration: .type1
            ),
            Self(
                id: "2",
                title: String(localized: "entry.type2", bundle: .module),
                detail: String(localized: "entry.detail2", bundle: .module),
                illustration: .type2
            ),
            Self(
                id: "3",
                title: String(localized: "entry.type3", bundle: .module),
                detail: String(localized: "entry.detail3", bundle: .module),
                illustration: .type3
            ),
            Self(
                id: "4",
                title: String(localized: "entry.type4", bundle: .module),
                detail: String(localized: "entry.detail4", bundle: .module),
                illustration: .type4
            ),
            Self(
                id: "5",
                title: String(localized: "entry.type5", bundle: .module),
                detail: String(localized: "entry.detail5", bundle: .module),
                illustration: .type5
            ),
            Self(
                id: "6",
                title: String(localized: "entry.type6", bundle: .module),
                detail: String(localized: "entry.detail6", bundle: .module),
                illustration: .type6
            ),
            Self(
                id: "7",
                title: String(localized: "entry.type7", bundle: .module),
                detail: String(localized: "entry.detail7", bundle: .module),
                illustration: .type7
            ),
            Self(id: "skip", title: String(localized: "entry.skipType", bundle: .module), detail: "", illustration: nil),
        ]
    }

    static var amounts: [Self] {
        [
            Self(
                id: "verySmall",
                title: String(localized: "entry.amount.verySmall", bundle: .module),
                detail: "",
                illustration: .amount1
            ),
            Self(
                id: "small",
                title: String(localized: "entry.amount.small", bundle: .module),
                detail: "",
                illustration: .amount2
            ),
            Self(
                id: "medium",
                title: String(localized: "entry.amount.medium", bundle: .module),
                detail: "",
                illustration: .amount3
            ),
            Self(
                id: "large",
                title: String(localized: "entry.amount.large", bundle: .module),
                detail: "",
                illustration: .amount4
            ),
            Self(
                id: "veryLarge",
                title: String(localized: "entry.amount.veryLarge", bundle: .module),
                detail: "",
                illustration: .amount5
            ),
        ]
    }

    static var efforts: [Self] {
        [
            Self(id: "easy", title: String(localized: "entry.effort.easy", bundle: .module), detail: "", illustration: nil),
            Self(
                id: "moderate",
                title: String(localized: "entry.effort.moderate", bundle: .module),
                detail: "",
                illustration: nil
            ),
            Self(
                id: "difficult",
                title: String(localized: "entry.effort.difficult", bundle: .module),
                detail: "",
                illustration: nil
            ),
        ]
    }
}
