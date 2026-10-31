import Foundation

struct EntryChoiceViewData: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let illustration: EntryIllustrationKind?
    let badge: String?

    init(
        id: String, title: String, detail: String = "",
        illustration: EntryIllustrationKind? = nil, badge: String? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.illustration = illustration
        self.badge = badge
    }

    static var types: [Self] {
        [
            Self(id: "1", title: String(localized: "entry.type1", bundle: .module),
                 detail: String(localized: "entry.detail1", bundle: .module), illustration: .type1, badge: "1"),
            Self(id: "2", title: String(localized: "entry.type2", bundle: .module),
                 detail: String(localized: "entry.detail2", bundle: .module), illustration: .type2, badge: "2"),
            Self(id: "3", title: String(localized: "entry.type3", bundle: .module),
                 detail: String(localized: "entry.detail3", bundle: .module), illustration: .type3, badge: "3"),
            Self(id: "4", title: String(localized: "entry.type4", bundle: .module),
                 detail: String(localized: "entry.detail4", bundle: .module), illustration: .type4, badge: "4"),
            Self(id: "5", title: String(localized: "entry.type5", bundle: .module),
                 detail: String(localized: "entry.detail5", bundle: .module), illustration: .type5, badge: "5"),
            Self(id: "6", title: String(localized: "entry.type6", bundle: .module),
                 detail: String(localized: "entry.detail6", bundle: .module), illustration: .type6, badge: "6"),
            Self(id: "7", title: String(localized: "entry.type7", bundle: .module),
                 detail: String(localized: "entry.detail7", bundle: .module), illustration: .type7, badge: "7"),
        ]
    }

    static var amounts: [Self] {
        [
            Self(id: "verySmall", title: String(localized: "entry.amount.verySmall", bundle: .module), illustration: .amount1),
            Self(id: "small", title: String(localized: "entry.amount.small", bundle: .module), illustration: .amount2),
            Self(id: "medium", title: String(localized: "entry.amount.medium", bundle: .module), illustration: .amount3),
            Self(id: "large", title: String(localized: "entry.amount.large", bundle: .module), illustration: .amount4),
            Self(id: "veryLarge", title: String(localized: "entry.amount.veryLarge", bundle: .module), illustration: .amount5),
        ]
    }

    static var efforts: [Self] {
        [
            Self(id: "easy", title: String(localized: "entry.effort.easy", bundle: .module)),
            Self(id: "moderate", title: String(localized: "entry.effort.moderate", bundle: .module)),
            Self(id: "difficult", title: String(localized: "entry.effort.difficult", bundle: .module)),
        ]
    }

    static var bloods: [Self] {
        [
            Self(id: "none", title: String(localized: "entry.blood.none", bundle: .module)),
            Self(id: "seen", title: String(localized: "entry.blood.seen", bundle: .module)),
        ]
    }

    static var colors: [Self] {
        [
            Self(id: "pale", title: String(localized: "entry.color.pale", bundle: .module)),
            Self(id: "yellow", title: String(localized: "entry.color.yellow", bundle: .module)),
            Self(id: "tan", title: String(localized: "entry.color.tan", bundle: .module)),
            Self(id: "orange", title: String(localized: "entry.color.orange", bundle: .module)),
            Self(id: "brown", title: String(localized: "entry.color.brown", bundle: .module)),
            Self(id: "green", title: String(localized: "entry.color.green", bundle: .module)),
            Self(id: "black", title: String(localized: "entry.color.black", bundle: .module)),
            Self(id: "red", title: String(localized: "entry.color.red", bundle: .module)),
        ]
    }

    static var durations: [Self] {
        [
            Self(id: "underTwo", title: String(localized: "entry.duration.underTwo", bundle: .module)),
            Self(id: "twoToFive", title: String(localized: "entry.duration.twoToFive", bundle: .module)),
            Self(id: "fiveToTen", title: String(localized: "entry.duration.fiveToTen", bundle: .module)),
            Self(id: "overTen", title: String(localized: "entry.duration.overTen", bundle: .module)),
        ]
    }

    static var suggestions: [Self] {
        [
            Self(id: "sticky", title: String(localized: "entry.suggestion.sticky", bundle: .module)),
            Self(id: "smelly", title: String(localized: "entry.suggestion.smelly", bundle: .module)),
            Self(id: "gassy", title: String(localized: "entry.suggestion.gassy", bundle: .module)),
            Self(id: "bloating", title: String(localized: "entry.suggestion.bloating", bundle: .module)),
            Self(id: "incomplete", title: String(localized: "entry.suggestion.incomplete", bundle: .module)),
            Self(id: "cramp", title: String(localized: "entry.suggestion.cramp", bundle: .module)),
            Self(id: "rectalPain", title: String(localized: "entry.suggestion.rectalPain", bundle: .module)),
        ]
    }
}
