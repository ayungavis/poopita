import DesignSystem
import SwiftUI

struct SettingsDataView: View {
    let csvExport: SettingsExportViewData
    let pdfExport: SettingsExportViewData

    var body: some View {
        CardSectionView("settings.data.title") {
            SettingsExportRowView(item: pdfExport, title: "settings.data.exportPDF", format: "PDF")
            CardDividerView()
            SettingsExportRowView(item: csvExport, title: "settings.data.exportCSV", format: "CSV")
            CardDividerView()
            HStack(spacing: Spacing.sm) {
                Text("settings.backup.title", bundle: .module)
                Spacer(minLength: Spacing.md)
                Text("settings.backup.notSetUp", bundle: .module)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .cardRow()
            .accessibilityElement(children: .combine)
            CardDividerView()
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
                    .cardRow()
            }
            .foregroundStyle(AppColor.textSecondary)
        }
    }
}
