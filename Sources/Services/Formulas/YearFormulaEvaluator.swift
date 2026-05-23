import Foundation

/// =YEAR() returns the current 4-digit year.
enum YearFormulaEvaluator {
    static func evaluate(now: Date = Date(), timeZone: TimeZone = .current) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timeZone
        return String(cal.component(.year, from: now))
    }
}
