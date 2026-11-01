import DesignSystem
import SwiftUI

struct SettingsDataView: View {
    let csvExport: SettingsExportViewData
    let pdfExport: SettingsExportViewData

    var body: some View {
        SettingsSectionView("settings.data.title") {
            exportRow(pdfExport, title: "settings.data.exportPDF", format: "PDF")
            SettingsDividerView()
            exportRow(csvExport, title: "settings.data.exportCSV", format: "CSV")
            SettingsDividerView()
            HStack(spacing: Spacing.sm) {
                Text("settings.backup.title", bundle: .module)
                Spacer(minLength: Spacing.md)
                Text("settings.backup.notSetUp", bundle: .module)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .settingsRow()
            .accessibilityElement(children: .combine)
            SettingsDividerView()
            DisclosureGroup {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("settings.backup.explainer1", bundle: .module)
                    Text("settings.backup.explainer2", bundle: .module)
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.bottom, Spacing.md)
            } label: {
                Text("settings.backup.howItWorks", bundle: .module)
                    .settingsRow()
            }
            .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func exportRow(_ item: SettingsExportViewData, title: LocalizedStringKey, format: String) -> some View {
        ShareLink(item: item, preview: SharePreview(Text(title, bundle: .module))) {
            HStack(spacing: Spacing.sm) {
                Text(title, bundle: .module)
                Spacer(minLength: Spacing.md)
                Text(verbatim: format)
                    .foregroundStyle(AppColor.textSecondary)
                Image(systemName: "chevron.right")
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .settingsRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
