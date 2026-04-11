import Foundation

/// =day() returns the current weekday name in the user's locale.
enum DayFormulaEvaluator {
    static func evaluate(now: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: now)
    }
}
