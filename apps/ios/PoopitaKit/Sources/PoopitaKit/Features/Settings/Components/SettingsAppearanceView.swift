import DesignSystem
import SwiftUI

struct SettingsAppearanceView: View {
    let data: SettingsAppearanceViewData
    let selectTheme: (String) -> Void
    let selectLanguage: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("settings.appearance.title", bundle: .module)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            ViewThatFits(in: .horizontal) {
                HStack {
                    label("settings.appearance.theme")
                    Spacer(minLength: Spacing.md)
                    themePicker.fixedSize()
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    label("settings.appearance.theme")
                    themePicker
                }
            }

            languageMenu

            if let note = data.languageNote {
                Text(verbatim: note)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .transition(.opacity)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.lg))
        .animation(.snappy, value: data.languageNote)
    }

    private var themePicker: some View {
        Picker(selection: Binding(get: { data.selectedThemeID }, set: selectTheme)) {
            ForEach(data.themes) { theme in
                Text(verbatim: theme.title).tag(theme.id)
            }
        } label: {
            Text("settings.appearance.theme", bundle: .module)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var languageMenu: some View {
        Menu {
            Picker(selection: Binding(get: { data.selectedLanguageID }, set: selectLanguage)) {
                ForEach(data.languages) { language in
                    Text(verbatim: language.title).tag(language.id)
                }
            } label: {
                Text("settings.appearance.language", bundle: .module)
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                label("settings.appearance.language")
                Spacer(minLength: Spacing.md)
                Text(verbatim: data.languageName)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Spacing.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func label(_ key: LocalizedStringKey) -> some View {
        Text(key, bundle: .module)
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
    }
}
