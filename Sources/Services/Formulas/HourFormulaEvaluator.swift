import Foundation

/// =HOUR() returns the current hour, 0-23.
enum HourFormulaEvaluator {
    static func evaluate(now: Date = Date(), timeZone: TimeZone = .current) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timeZone
        return String(cal.component(.hour, from: now))
    }
}
