#if os(iOS)
    import SwiftUI
    import WidgetKit

    public struct QuickLogWidget: Widget {
        public init() {}

        public var body: some WidgetConfiguration {
            StaticConfiguration(kind: "QuickLogWidget", provider: QuickLogTimeline()) { _ in
                QuickLogWidgetView()
            }
            .configurationDisplayName(Text("widget.log.name", bundle: .module))
            .description(Text("widget.log.description", bundle: .module))
            .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
        }
    }

    struct QuickLogTimeline: TimelineProvider {
        struct Entry: TimelineEntry {
            let date: Date
        }

        func placeholder(in _: Context) -> Entry {
            Entry(date: .now)
        }

        func getSnapshot(in _: Context, completion: @escaping (Entry) -> Void) {
            completion(Entry(date: .now))
        }

        func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
            completion(Timeline(entries: [Entry(date: .now)], policy: .never))
        }
    }
#endif
