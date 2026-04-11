import Foundation

/// =time() returns the current time as HH:mm in 24-hour form.
enum TimeFormulaEvaluator {
    static func evaluate(now: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: now)
    }
}
