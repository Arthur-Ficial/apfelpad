import Foundation

/// =WEEKDAY() returns 1-7 per Google Sheets default (1 = Sunday, 7 = Saturday).
enum WeekdayFormulaEvaluator {
    static func evaluate(now: Date = Date(), timeZone: TimeZone = .current) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        // Calendar.weekday in .gregorian is 1=Sunday..7=Saturday already.
        return String(cal.component(.weekday, from: now))
    }
}
