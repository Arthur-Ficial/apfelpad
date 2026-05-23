import Testing
import Foundation
@testable import apfelpad

@Suite("Phase 5 date/time: NOW, YEAR, WEEKDAY, HOUR, MINUTE, SECOND")
struct Phase5DateTimeFormulasTests {
    // MARK: - NOW

    @Test("NOW with a fixed date renders YYYY-MM-DD HH:mm")
    func nowFormat() {
        // 2026-04-12 17:30:45 UTC, but we render in current TZ — use a
        // deterministic GMT calendar to assert structure not exact value.
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 12
        components.hour = 17
        components.minute = 30
        components.timeZone = TimeZone(identifier: "UTC")
        let date = Calendar(identifier: .iso8601).date(from: components)!
        let result = NowFormulaEvaluator.evaluate(now: date, timeZone: TimeZone(identifier: "UTC")!)
        #expect(result == "2026-04-12 17:30")
    }

    @Test("NOW with default args is at least 16 chars and contains both date and time separators")
    func nowDefault() {
        let result = NowFormulaEvaluator.evaluate()
        #expect(result.count >= 16)
        #expect(result.contains("-"))
        #expect(result.contains(":"))
        #expect(result.contains(" "))
    }

    // MARK: - YEAR

    @Test("YEAR returns 4 digits and is at least 2026")
    func yearFormat() {
        let result = YearFormulaEvaluator.evaluate()
        #expect(result.count == 4)
        let int = Int(result)
        #expect(int != nil)
        #expect((int ?? 0) >= 2026)
    }

    @Test("YEAR with injected date returns that year")
    func yearFixedDate() {
        var components = DateComponents()
        components.year = 2030
        components.month = 1
        components.day = 1
        components.timeZone = TimeZone(identifier: "UTC")
        let date = Calendar(identifier: .iso8601).date(from: components)!
        let result = YearFormulaEvaluator.evaluate(now: date, timeZone: TimeZone(identifier: "UTC")!)
        #expect(result == "2030")
    }

    // MARK: - WEEKDAY

    @Test("WEEKDAY returns a number 1-7")
    func weekdayRange() {
        let result = Int(WeekdayFormulaEvaluator.evaluate())
        #expect(result != nil)
        let n = result ?? 0
        #expect((1...7).contains(n))
    }

    @Test("WEEKDAY on a known Sunday returns 1 (Google Sheets convention)")
    func weekdaySunday() {
        // 2026-04-12 is a Sunday (per ISO 8601 cal)
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 12
        components.timeZone = TimeZone(identifier: "UTC")
        let date = Calendar(identifier: .iso8601).date(from: components)!
        let result = WeekdayFormulaEvaluator.evaluate(now: date, timeZone: TimeZone(identifier: "UTC")!)
        #expect(result == "1")
    }

    @Test("WEEKDAY on a known Saturday returns 7")
    func weekdaySaturday() {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 18
        components.timeZone = TimeZone(identifier: "UTC")
        let date = Calendar(identifier: .iso8601).date(from: components)!
        let result = WeekdayFormulaEvaluator.evaluate(now: date, timeZone: TimeZone(identifier: "UTC")!)
        #expect(result == "7")
    }

    // MARK: - HOUR

    @Test("HOUR returns a number 0-23")
    func hourRange() {
        let n = Int(HourFormulaEvaluator.evaluate()) ?? -1
        #expect((0...23).contains(n))
    }

    @Test("HOUR at injected 17:30 UTC returns 17")
    func hourFixed() {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 12
        components.hour = 17
        components.minute = 30
        components.timeZone = TimeZone(identifier: "UTC")
        let date = Calendar(identifier: .iso8601).date(from: components)!
        let result = HourFormulaEvaluator.evaluate(now: date, timeZone: TimeZone(identifier: "UTC")!)
        #expect(result == "17")
    }

    // MARK: - MINUTE

    @Test("MINUTE returns a number 0-59")
    func minuteRange() {
        let n = Int(MinuteFormulaEvaluator.evaluate()) ?? -1
        #expect((0...59).contains(n))
    }

    @Test("MINUTE at injected 17:30 returns 30")
    func minuteFixed() {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 12
        components.hour = 17
        components.minute = 30
        components.timeZone = TimeZone(identifier: "UTC")
        let date = Calendar(identifier: .iso8601).date(from: components)!
        let result = MinuteFormulaEvaluator.evaluate(now: date, timeZone: TimeZone(identifier: "UTC")!)
        #expect(result == "30")
    }

    // MARK: - SECOND

    @Test("SECOND returns a number 0-59")
    func secondRange() {
        let n = Int(SecondFormulaEvaluator.evaluate()) ?? -1
        #expect((0...59).contains(n))
    }

    @Test("SECOND at injected 17:30:45 returns 45")
    func secondFixed() {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 12
        components.hour = 17
        components.minute = 30
        components.second = 45
        components.timeZone = TimeZone(identifier: "UTC")
        let date = Calendar(identifier: .iso8601).date(from: components)!
        let result = SecondFormulaEvaluator.evaluate(now: date, timeZone: TimeZone(identifier: "UTC")!)
        #expect(result == "45")
    }

    // MARK: - Parser integration

    @Test("Parser parses =NOW() (case-insensitive)")
    func parserNow() throws {
        #expect(try FormulaParser.parse("=NOW()") == .now)
        #expect(try FormulaParser.parse("=now()") == .now)
    }

    @Test("Parser parses =YEAR()")
    func parserYear() throws {
        #expect(try FormulaParser.parse("=YEAR()") == .year)
    }

    @Test("Parser parses =WEEKDAY()")
    func parserWeekday() throws {
        #expect(try FormulaParser.parse("=WEEKDAY()") == .weekday)
    }

    @Test("Parser parses =HOUR(), =MINUTE(), =SECOND()")
    func parserClockParts() throws {
        #expect(try FormulaParser.parse("=HOUR()") == .hour)
        #expect(try FormulaParser.parse("=MINUTE()") == .minute)
        #expect(try FormulaParser.parse("=SECOND()") == .second)
    }

    @Test("Parser accepts bare =now / =year / =hour / =minute / =second (no parens)")
    func parserBareForms() throws {
        #expect(try FormulaParser.parse("=now") == .now)
        #expect(try FormulaParser.parse("=year") == .year)
        #expect(try FormulaParser.parse("=hour") == .hour)
        #expect(try FormulaParser.parse("=minute") == .minute)
        #expect(try FormulaParser.parse("=second") == .second)
        #expect(try FormulaParser.parse("=weekday") == .weekday)
    }

    // MARK: - Sync evaluator integration

    @Test("Sync evaluator dispatches all six new formulas")
    func syncEvaluatorDispatch() throws {
        let now = try FormulaSyncEvaluator.evaluate(.now)
        let year = try FormulaSyncEvaluator.evaluate(.year)
        let weekday = try FormulaSyncEvaluator.evaluate(.weekday)
        let hour = try FormulaSyncEvaluator.evaluate(.hour)
        let minute = try FormulaSyncEvaluator.evaluate(.minute)
        let second = try FormulaSyncEvaluator.evaluate(.second)
        #expect(now.contains(" "))
        #expect(year.count == 4)
        #expect((1...7).contains(Int(weekday) ?? 0))
        #expect((0...23).contains(Int(hour) ?? -1))
        #expect((0...59).contains(Int(minute) ?? -1))
        #expect((0...59).contains(Int(second) ?? -1))
    }

    // MARK: - Registry

    @Test("Registry exposes all six new formulas")
    func registryEntries() {
        for name in ["now", "year", "weekday", "hour", "minute", "second"] {
            #expect(FormulaRegistry.definition(forFunctionName: name) != nil)
        }
    }
}
