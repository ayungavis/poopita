#if os(iOS)
    import DesignSystem
    import SwiftUI
    import WidgetKit

    struct QuickLogWidgetView: View {
        @Environment(\.widgetFamily) private var family

        var body: some View {
            content
                .widgetURL(QuickLogLink.url)
                .containerBackground(for: .widget) { AppColor.surface }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("widget.log.name", bundle: .module))
                .accessibilityAddTraits(.isButton)
        }

        @ViewBuilder
        private var content: some View {
            switch family {
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "plus")
                        .font(AppFont.title)
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "Poopita")
                        .font(AppFont.caption.weight(.semibold))
                    Label {
                        Text("widget.log.title", bundle: .module)
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .font(AppFont.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Image(systemName: "plus")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.onInk)
                        .frame(width: Spacing.touchTarget, height: Spacing.touchTarget)
                        .background(AppColor.ink, in: Circle())
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                    Text("widget.log.title", bundle: .module)
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("widget.log.detail", bundle: .module)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
    }
#endif
