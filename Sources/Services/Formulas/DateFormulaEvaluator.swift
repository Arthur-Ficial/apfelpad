import Foundation

/// =date() returns today's date in ISO 8601 (YYYY-MM-DD).
/// =date(+N) / =date(-N) offsets by N days.
enum DateFormulaEvaluator {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }()

    static func evaluate(offsetDays: Int, now: Date = Date()) -> String {
        let shifted = Calendar(identifier: .iso8601).date(
            byAdding: .day, value: offsetDays, to: now
        ) ?? now
        return formatter.string(from: shifted)
    }
}
