import Foundation
#if canImport(UIKit)
    import UIKit
#endif

struct DiaryReport: Equatable {
    struct Line: Equatable {
        let heading: String
        let detail: String
    }

    let title: String
    let summary: [String]
    let lines: [Line]

    init(entries: [DiaryEntry], checkIns: [NoPoopCheckIn], now: Date) {
        let sorted = entries.sorted { $0.occurrence.instant < $1.occurrence.instant }
        title = String(localized: "settings.report.title", bundle: .module)
        var summary = [String(localized: "settings.report.created \(now.formatted(date: .long, time: .shortened))",
                              bundle: .module)]
        if let first = sorted.first?.occurrence.instant, let last = sorted.last?.occurrence.instant {
            let period = (first ..< last).formatted(.interval.day().month().year())
            summary.append(String(localized: "settings.report.period \(period)", bundle: .module))
        }
        summary.append(String(localized: "settings.report.logs \(sorted.count)", bundle: .module))
        self.summary = summary
        let entryLines = sorted.map { entry in
            (entry.occurrence.instant, Line(heading: Self.heading(entry.occurrence), detail: Self.detail(entry)))
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        var dayStyle = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()
        dayStyle.timeZone = .gmt
        let checkInLines = checkIns.filter { $0.coverage == .completed }.compactMap { checkIn -> (Date, Line)? in
            let parts = DateComponents(year: checkIn.day.year, month: checkIn.day.month, day: checkIn.day.day, hour: 23)
            guard let day = calendar.date(from: parts) else { return nil }
            return (day, Line(
                heading: day.formatted(dayStyle), detail: String(localized: "settings.report.checkIn", bundle: .module)
            ))
        }
        let all = (entryLines + checkInLines).sorted { $0.0 < $1.0 }.map(\.1)
        lines = all.isEmpty
            ? [Line(heading: "", detail: String(localized: "settings.report.empty", bundle: .module))] : all
    }

    private static func heading(_ time: OccurrenceTime) -> String {
        var style = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated).year().hour().minute()
        style.timeZone = TimeZone(identifier: time.timeZoneIdentifier) ?? .current
        return time.instant.formatted(style)
    }

    private static func detail(_ entry: DiaryEntry) -> String {
        var parts: [String] = []
        if let type = entry.stoolType, let choice = EntryChoiceViewData.types.first(where: { $0.id == String(type) }) {
            parts.append(choice.title + " · " + choice.detail)
        } else {
            parts.append(String(localized: "entry.typeSkipped", bundle: .module))
        }
        parts += [
            field("entry.amountLabel", entry.amount?.rawValue, EntryChoiceViewData.amounts),
            field("entry.effortLabel", entry.effort?.rawValue, EntryChoiceViewData.efforts),
            field("entry.bloodLabel", entry.blood?.rawValue, EntryChoiceViewData.bloods),
            field("entry.colorLabel", entry.color?.rawValue, EntryChoiceViewData.colors),
            field("entry.durationLabel", entry.duration?.rawValue, EntryChoiceViewData.durations),
        ].compactMap(\.self)
        if !entry.note.isEmpty {
            parts.append("“\(entry.note)”")
        }
        return parts.joined(separator: " · ")
    }

    private static func field(
        _ label: String.LocalizationValue, _ value: String?, _ choices: [EntryChoiceViewData]
    ) -> String? {
        guard let value, let choice = choices.first(where: { $0.id == value }) else { return nil }
        return String(localized: label, bundle: .module) + ": " + choice.title
    }

    func pdf() -> Data {
        #if canImport(UIKit)
            let page = CGRect(x: 0, y: 0, width: 595, height: 842)
            let margin: CGFloat = 48
            let width = page.width - margin * 2
            let titleFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
            let headingFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 10)
            return UIGraphicsPDFRenderer(bounds: page).pdfData { context in
                var cursor = margin
                context.beginPage()
                func draw(_ text: String, font: UIFont, color: UIColor = .black, after spacing: CGFloat) {
                    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                    let height = ceil((text as NSString).boundingRect(
                        with: CGSize(width: width, height: .greatestFiniteMagnitude),
                        options: .usesLineFragmentOrigin, attributes: attributes, context: nil
                    ).height)
                    if cursor + height > page.height - margin {
                        context.beginPage()
                        cursor = margin
                    }
                    (text as NSString).draw(
                        with: CGRect(x: margin, y: cursor, width: width, height: height),
                        options: .usesLineFragmentOrigin, attributes: attributes, context: nil
                    )
                    cursor += height + spacing
                }
                draw(title, font: titleFont, after: 8)
                for line in summary {
                    draw(line, font: bodyFont, color: .darkGray, after: 2)
                }
                cursor += 14
                for line in lines {
                    if !line.heading.isEmpty {
                        draw(line.heading, font: headingFont, after: 2)
                    }
                    draw(line.detail, font: bodyFont, after: 10)
                }
            }
        #else
            Data()
        #endif
    }
}
