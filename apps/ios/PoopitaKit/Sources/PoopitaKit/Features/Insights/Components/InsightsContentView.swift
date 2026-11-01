import DesignSystem
import SwiftUI

struct InsightsContentView: View {
    let viewModel: InsightsViewModel
    let data: InsightsViewData
    let doctorExport: SettingsExportViewData
    let showFrequency: () -> Void
    let openDay: (String) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var headerHeight: CGFloat = 0
    @State private var isHeaderHidden = false
    @State private var showsGuide = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    PeriodHeaderView(
                        title: data.title, detail: data.detail, accessibilityLabel: data.accessibilityLabel,
                        canMoveNext: data.canMoveNext, move: viewModel.move
                    )
                    InsightsPeriodPickerView(selection: data.period, select: viewModel.select)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                summary
                if !data.doctor.isEmpty {
                    InsightsFlagsView(flags: data.doctor, isDoctor: true, export: doctorExport, openDay: openDay)
                }
                if !data.changes.isEmpty {
                    InsightsFlagsView(flags: data.changes, isDoctor: false, export: nil, openDay: openDay)
                }
                InsightsUsualView(data: data.usual)
                if !data.consistency.rows.isEmpty {
                    InsightsConsistencyView(data: data.consistency)
                }
                section("insights.when", link: "insights.frequency", action: showFrequency)
                InsightsWhenChartView(data: data.when)
                if !data.comfort.isEmpty {
                    InsightsComfortView(rows: data.comfort)
                }
                if !data.types.isEmpty {
                    section("insights.type", link: "insights.bristolGuide") { showsGuide = true }
                    CardSectionView(nil) {
                        ForEach(data.types) { type in
                            if type.id != data.types.first?.id {
                                CardDividerView()
                            }
                            InsightsTypeRowView(type: type)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: data)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > headerHeight
        } action: { _, isHidden in
            isHeaderHidden = isHidden
        }
        .background(AppColor.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(verbatim: data.accessibilityLabel)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .contentTransition(.opacity)
                    .opacity(isHeaderHidden ? 1 : 0)
                    .offset(y: isHeaderHidden || reduceMotion ? 0 : Spacing.sm)
                    .accessibilityHidden(!isHeaderHidden)
                    .animation(.snappy(duration: 0.25), value: isHeaderHidden)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .sheet(isPresented: $showsGuide) {
            NavigationStack {
                BristolGuideView(guide: .standard)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button { showsGuide = false } label: {
                                Text("entry.done", bundle: .module)
                            }
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(verbatim: data.headline)
                .font(AppFont.statement)
                .foregroundStyle(AppColor.textPrimary)
                .contentTransition(.numericText())
                .fixedSize(horizontal: false, vertical: true)
            if let detail = data.headlineDetail {
                Text(verbatim: detail)
                    .foregroundStyle(AppColor.textSecondary)
            }
            if data.summaryNote != nil || data.unrecorded != nil {
                comparisonRow
            }
        }
        .padding(.top, Spacing.sm)
    }

    private var comparisonRow: some View {
        HStack {
            if let note = data.summaryNote {
                Text(verbatim: note)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: Spacing.sm)
            if let unrecorded = data.unrecorded {
                link(Text(verbatim: unrecorded.label)) { openDay(unrecorded.dayID) }
            }
        }
        .padding(.top, Spacing.sm)
    }

    private func section(_ title: LocalizedStringKey, link key: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title, bundle: .module)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.sm)
            link(Text(key, bundle: .module), action: action)
        }
        .padding(.top, Spacing.sm)
    }

    private func link(_ title: Text, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                title
                Image(systemName: "chevron.right")
                    .font(AppFont.caption.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .font(AppFont.caption.weight(.semibold))
            .foregroundStyle(AppColor.accent)
            .frame(minHeight: Spacing.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, -Spacing.md)
    }
}
