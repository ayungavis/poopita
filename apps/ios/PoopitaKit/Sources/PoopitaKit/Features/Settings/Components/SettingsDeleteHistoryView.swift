import DesignSystem
import SwiftUI

struct SettingsDeleteHistoryView: View {
    let viewModel: SettingsViewModel
    let close: () -> Void
    @State private var data: SettingsDeleteViewData?
    @State private var typed = ""
    @State private var errorMessage: String?
    @FocusState private var isTyping: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl - Spacing.xs) {
                if let data {
                    if data.isEmpty {
                        empty
                    } else {
                        Text("settings.delete.intro", bundle: .module)
                            .foregroundStyle(AppColor.textSecondary)
                        content(data)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColor.background)
        .navigationTitle(Text("settings.data.deleteAll", bundle: .module))
        .font(AppFont.body)
        .task { data = viewModel.deleteViewData() }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("settings.delete.empty", bundle: .module)
                .font(AppFont.body.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
            Text("settings.delete.emptyDetail", bundle: .module)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func content(_ data: SettingsDeleteViewData) -> some View {
        CardSectionView("settings.delete.deleted") {
            valueRow("settings.delete.logs", data.logs)
            CardDividerView()
            valueRow("settings.delete.checkIns", data.checkIns)
            if let since = data.since {
                CardDividerView()
                valueRow("settings.delete.since", since)
            }
        }
        CardSectionView("settings.delete.stays") {
            Text("settings.delete.staysDetail", bundle: .module)
                .cardRow()
        }
        CardSectionView("settings.delete.copy") {
            SettingsExportRowView(item: viewModel.pdfExport, title: "settings.data.exportPDF", format: "PDF")
            CardDividerView()
            SettingsExportRowView(item: viewModel.csvExport, title: "settings.data.exportCSV", format: "CSV")
        }
        confirmation(data)
    }

    private func confirmation(_ data: SettingsDeleteViewData) -> some View {
        let canDelete = SettingsViewModel.confirms(typed, word: data.confirmWord)
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("settings.delete.typePrompt \(data.confirmWord)", bundle: .module)
                .font(AppFont.caption.weight(.medium))
                .foregroundStyle(AppColor.textSecondary)
            TextField(text: $typed) {
                Text(verbatim: data.confirmWord)
            }
            .focused($isTyping)
            .autocorrectionDisabled()
            .capitalizeCharacters()
            .submitLabel(.done)
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: Spacing.touchTarget + Spacing.xs)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.destructive)
            }
            Button(action: delete) {
                Text("settings.data.deleteAll", bundle: .module)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.onInk)
                    .frame(maxWidth: .infinity, minHeight: Spacing.buttonHeight)
                    .background(AppColor.destructive, in: Capsule())
                    .opacity(canDelete ? 1 : 0.4)
            }
            .buttonStyle(.plain)
            .disabled(!canDelete)
            .padding(.top, Spacing.sm)
            .accessibilityHint(Text("settings.delete.hint", bundle: .module))
            .sensoryFeedback(.warning, trigger: canDelete) { _, ready in ready }
        }
    }

    private func valueRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(title, bundle: .module)
            Spacer(minLength: Spacing.md)
            Text(verbatim: value)
                .foregroundStyle(AppColor.textSecondary)
        }
        .cardRow()
        .accessibilityElement(children: .combine)
    }

    private func delete() {
        isTyping = false
        do {
            try viewModel.deleteAllHistory()
            close()
        } catch {
            errorMessage = AppError(wrapping: error).userMessage
        }
    }
}

private extension View {
    func capitalizeCharacters() -> some View {
        #if os(iOS)
            textInputAutocapitalization(.characters)
        #else
            self
        #endif
    }
}
