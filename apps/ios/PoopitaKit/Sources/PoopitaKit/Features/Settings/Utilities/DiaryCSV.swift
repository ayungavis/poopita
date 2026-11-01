import Foundation

enum DiaryCSV {
    static let header = "kind,date,time,time_zone,stool_type,amount,effort,blood,color,duration,note"

    static func make(entries: [DiaryEntry], checkIns: [NoPoopCheckIn]) -> String {
        let entryRows = entries.sorted { $0.occurrence.instant < $1.occurrence.instant }.map { entry in
            row([
                "entry", DiaryDay(occurrence: entry.occurrence).id, time(entry.occurrence), entry.occurrence.timeZoneIdentifier,
                entry.stoolType.map(String.init) ?? "", entry.amount?.rawValue ?? "", entry.effort?.rawValue ?? "",
                entry.blood?.rawValue ?? "", entry.color?.rawValue ?? "", entry.duration?.rawValue ?? "", entry.note,
            ])
        }
        let checkInRows = checkIns.sorted { $0.day < $1.day }.map { checkIn in
            row([
                "check_in_\(checkIn.coverage.rawValue)",
                checkIn.day.id,
                "", checkIn.reportedAt.timeZoneIdentifier, "", "", "", "", "", "", "",
            ])
        }
        return ([header] + entryRows + checkInRows).joined(separator: "\n") + "\n"
    }

    private static func row(_ fields: [String]) -> String {
        fields.map(escape).joined(separator: ",")
    }

    private static func escape(_ field: String) -> String {
        let safe = field.first.map { "=+-@".contains($0) } == true ? "'" + field : field
        guard safe.contains(where: { ",\"\n\r".contains($0) }) else { return safe }
        return "\"" + safe.replacing("\"", with: "\"\"") + "\""
    }

    private static func time(_ time: OccurrenceTime) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }
}
