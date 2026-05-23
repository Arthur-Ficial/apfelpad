import Foundation

/// =SECOND() returns the current second, 0-59.
enum SecondFormulaEvaluator {
    static func evaluate(now: Date = Date(), timeZone: TimeZone = .current) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timeZone
        return String(cal.component(.second, from: now))
    }
}
