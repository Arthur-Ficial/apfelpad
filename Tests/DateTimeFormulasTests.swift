import Testing
import Foundation
@testable import apfelpad

@Suite("Date / time formulas", .serialized)
struct DateTimeFormulasTests {
    // A fixed reference date so tests are deterministic.
    // 2026-04-15 is a Wednesday, ISO calendar week 16.
    private static let referenceDate: Date = {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 4
        comps.day = 15
        comps.hour = 14
        comps.minute = 30
        comps.second = 0
        comps.timeZone = TimeZone(identifier: "Europe/Vienna")
        return Calendar(identifier: .iso8601).date(from: comps)!
    }()

    // MARK: - =date

    @Test("=date() returns today in ISO 8601 (YYYY-MM-DD)")
    func dateToday() {
        let out = DateFormulaEvaluator.evaluate(offsetDays: 0, now: Self.referenceDate)
        #expect(out == "2026-04-15")
    }

    @Test("=date(+4) returns today plus 4 days")
    func datePlus() {
        let out = DateFormulaEvaluator.evaluate(offsetDays: 4, now: Self.referenceDate)
        #expect(out == "2026-04-19")
    }

    @Test("=date(-1) returns yesterday")
    func dateMinus() {
        let out = DateFormulaEvaluator.evaluate(offsetDays: -1, now: Self.referenceDate)
        #expect(out == "2026-04-14")
    }

    @Test("=date(+30) crosses month boundary")
    func dateCrossMonth() {
        let out = DateFormulaEvaluator.evaluate(offsetDays: 30, now: Self.referenceDate)
        #expect(out == "2026-05-15")
    }

    // MARK: - =weeknum

    @Test("=weeknum() returns current ISO calendar week")
    func weeknumCurrent() {
        let out = WeeknumFormulaEvaluator.evaluate(offsetWeeks: 0, now: Self.referenceDate)
        #expect(out == "16")
    }

    @Test("=weeknum(-1) returns previous week")
    func weeknumPrev() {
        let out = WeeknumFormulaEvaluator.evaluate(offsetWeeks: -1, now: Self.referenceDate)
        #expect(out == "15")
    }

    @Test("=weeknum(+2) returns two weeks ahead")
    func weeknumNext() {
        let out = WeeknumFormulaEvaluator.evaluate(offsetWeeks: 2, now: Self.referenceDate)
        #expect(out == "18")
    }

    // MARK: - =month / =day / =time

    @Test("=month() returns the current month name")
    func monthName() {
        let out = MonthFormulaEvaluator.evaluate(now: Self.referenceDate)
        #expect(out == "April")
    }

    @Test("=day() returns the weekday name")
    func dayName() {
        let out = DayFormulaEvaluator.evaluate(now: Self.referenceDate)
        #expect(out == "Wednesday")
    }

    @Test("=time() returns HH:mm")
    func time() {
        // The test reference date is 14:30 in Europe/Vienna. The evaluator
        // formats in the user's current locale — check that the result
        // parses to a 2-digit:2-digit time form.
        let out = TimeFormulaEvaluator.evaluate(now: Self.referenceDate)
        let parts = out.split(separator: ":")
        #expect(parts.count == 2)
        #expect(parts[0].count == 2)
        #expect(parts[1].count == 2)
    }
}
