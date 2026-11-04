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
        }
    }
}
