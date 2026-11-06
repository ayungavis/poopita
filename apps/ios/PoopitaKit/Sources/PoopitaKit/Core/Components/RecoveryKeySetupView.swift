import DesignSystem
import SwiftUI

struct RecoveryKeySetupView: View {
    let data: RecoveryKeySetupViewData
    let isWorking: Bool
    let confirm: (String) -> Void
    let cancel: () -> Void
    @State private var typed = ""
    @FocusState private var isTyping: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl - Spacing.xs) {
                    Text("backup.key.message", bundle: .module)
                        .foregroundStyle(AppColor.textSecondary)
                    RecoveryKeyGridView(groups: data.groups, shareText: data.shareText)
                    confirmation
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColor.background)
            .navigationTitle(Text("backup.key.title", bundle: .module))
            .font(AppFont.body)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: cancel) {
                        Text("entry.cancel", bundle: .module)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isWorking)
    }

    private var confirmation: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(verbatim: data.confirmPrompt)
                .font(AppFont.caption.weight(.medium))
                .foregroundStyle(AppColor.textSecondary)
            TextField(text: $typed) {
                Text(verbatim: "XXXX")
            }
            .focused($isTyping)
            .autocorrectionDisabled()
            .keyboardCharacters()
            .submitLabel(.done)
            .onSubmit(submit)
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: Spacing.touchTarget + Spacing.xs)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Spacing.md))
            if let error = data.errorMessage {
                Text(verbatim: error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.destructive)
            }
            PrimaryButtonView(Text("backup.key.confirm", bundle: .module), action: submit)
                .disabled(isWorking || typed.isEmpty)
                .padding(.top, Spacing.sm)
        }
        .onChange(of: data.errorMessage) { _, error in
            if let error {
                AccessibilityNotification.Announcement(error).post()
            }
        }
    }

    private func submit() {
        isTyping = false
        confirm(typed)
    }
}

extension View {
    func keyboardCharacters() -> some View {
        #if os(iOS)
            textInputAutocapitalization(.characters)
        #else
            self
        #endif
    }
}
