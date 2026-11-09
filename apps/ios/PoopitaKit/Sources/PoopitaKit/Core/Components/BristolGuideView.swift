import DesignSystem
import SwiftUI

struct BristolGuideView: View {
    let guide: BristolGuideViewData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl - Spacing.xs) {
                Text(verbatim: guide.intro)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
                ForEach(guide.groups) { group in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(verbatim: group.title)
                            .font(AppFont.caption.weight(.medium))
                            .foregroundStyle(AppColor.textSecondary)
                            .accessibilityAddTraits(.isHeader)
                        VStack(spacing: 0) {
                            ForEach(group.rows) { row in
                                if row.id != group.rows.first?.id {
                                    CardDividerView()
                                }
                                rowView(row)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
                    }
                }
                doctorCard
                Text(verbatim: guide.note)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AppColor.background)
        .navigationTitle(Text("settings.help.bristol", bundle: .module))
    }

    private var doctorCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label {
                Text(verbatim: guide.doctorTitle)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
            } icon: {
                Image(systemName: "stethoscope")
                    .foregroundStyle(AppColor.accent)
            }
            .accessibilityAddTraits(.isHeader)
            ForEach(guide.doctorSigns, id: \.self) { sign in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text(verbatim: "•")
                        .accessibilityHidden(true)
                    Text(verbatim: sign)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
        .accessibilityElement(children: .combine)
    }

    private func rowView(_ row: BristolGuideViewData.Row) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            if let illustration = row.illustration {
                EntryIllustrationView(kind: illustration)
                    .foregroundStyle(AppColor.textPrimary)
            }
            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                Text(verbatim: row.title)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(verbatim: row.description)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
