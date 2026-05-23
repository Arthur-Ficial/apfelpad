import Foundation

/// =MINUTE() returns the current minute, 0-59.
enum MinuteFormulaEvaluator {
    static func evaluate(now: Date = Date(), timeZone: TimeZone = .current) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timeZone
        return String(cal.component(.minute, from: now))
    }
}
