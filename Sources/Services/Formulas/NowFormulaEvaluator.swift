import Foundation

/// =NOW() returns the current date and time as `YYYY-MM-DD HH:mm`.
enum NowFormulaEvaluator {
    static func evaluate(now: Date = Date(), timeZone: TimeZone = .current) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = timeZone
        return f.string(from: now)
    }
}
