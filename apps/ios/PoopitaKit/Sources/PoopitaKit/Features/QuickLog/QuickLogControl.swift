#if os(iOS)
    import AppIntents
    import SwiftUI
    import WidgetKit

    public struct QuickLogControl: ControlWidget {
        public init() {}

        public var body: some ControlWidgetConfiguration {
            StaticControlConfiguration(kind: "QuickLogControl") {
                ControlWidgetButton(action: OpenURLIntent(QuickLogLink.url)) {
                    Label {
                        Text("widget.log.title", bundle: .module)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            }
            .displayName(LocalizedStringResource("widget.log.name", bundle: .atURL(Bundle.module.bundleURL)))
            .description(LocalizedStringResource("widget.log.description", bundle: .atURL(Bundle.module.bundleURL)))
        }
    }
#endif
