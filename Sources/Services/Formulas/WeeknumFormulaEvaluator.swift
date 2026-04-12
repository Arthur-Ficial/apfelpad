import Foundation

/// =weeknum() returns the current ISO calendar week (1–53).
/// =weeknum(+N) / =weeknum(-N) offsets by N weeks.
enum WeeknumFormulaEvaluator {
    static func evaluate(offsetWeeks: Int, now: Date = Date()) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2 // Monday — ISO standard
        let shifted = calendar.date(byAdding: .weekOfYear, value: offsetWeeks, to: now) ?? now
        let week = calendar.component(.weekOfYear, from: shifted)
        return String(week)
    }
}
