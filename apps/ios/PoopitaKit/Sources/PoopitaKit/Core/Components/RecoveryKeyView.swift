import DesignSystem
import SwiftUI

struct RecoveryKeyView: View {
    let data: RecoveryKeyDisplayViewData
    let done: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl - Spacing.xs) {
                    Text("backup.key.viewMessage", bundle: .module)
                        .foregroundStyle(AppColor.textSecondary)
                    RecoveryKeyGridView(groups: data.groups, shareText: data.shareText)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
            .background(AppColor.background)
            .navigationTitle(Text("settings.backup.key", bundle: .module))
            .font(AppFont.body)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: done) {
                        Text("entry.done", bundle: .module)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
