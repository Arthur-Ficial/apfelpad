import Foundation

/// =month() returns the current month name in the user's locale.
enum MonthFormulaEvaluator {
    static func evaluate(now: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: now)
    }
}
