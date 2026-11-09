import Foundation

struct BristolGuideViewData: Equatable, Sendable {
    struct Group: Identifiable, Equatable, Sendable {
        let id: String
        let title: String
        let rows: [Row]
    }

    struct Row: Identifiable, Equatable, Sendable {
        let id: String
        let title: String
        let description: String
        let illustration: EntryIllustrationKind?
    }

    let intro: String
    let groups: [Group]
    let doctorTitle: String
    let doctorSigns: [String]
    let note: String
}

extension BristolGuideViewData {
    static var standard: Self {
        let rows = EntryChoiceViewData.types.map { type in
            Self.Row(
                id: type.id, title: type.title + " · " + type.detail,
                description: String(
                    localized: String.LocalizationValue("settings.guide.desc" + type.id), bundle: .module
                ),
                illustration: type.illustration
            )
        }
        let group = { (id: String, title: String, range: Range<Int>) in
            Self.Group(id: id, title: title, rows: Array(rows[range]))
        }
        return Self(
            intro: String(localized: "settings.guide.intro", bundle: .module),
            groups: [
                group("harder", String(localized: "settings.guide.harder", bundle: .module), 0 ..< 2),
                group("typical", String(localized: "settings.guide.typical", bundle: .module), 2 ..< 4),
                group("looser", String(localized: "settings.guide.looser", bundle: .module), 4 ..< 7),
            ],
            doctorTitle: String(localized: "settings.guide.doctor.title", bundle: .module),
            doctorSigns: [
                String(localized: "settings.guide.doctor.blood", bundle: .module),
                String(localized: "settings.guide.doctor.color", bundle: .module),
                String(localized: "settings.guide.doctor.change", bundle: .module),
                String(localized: "settings.guide.doctor.pain", bundle: .module),
            ],
            note: String(localized: "settings.guide.note", bundle: .module)
        )
    }
}
