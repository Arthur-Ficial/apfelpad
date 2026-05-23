import Testing
import Foundation
@testable import apfelpad

@Suite("Phase 3 math: 27 functions")
struct Phase3MathFormulasTests {
    // MARK: - Variadic: MAX, MIN, PRODUCT
    @Test func maxBasic() throws { #expect(try MaxFormulaEvaluator.evaluate(["3", "1", "7", "4"]) == "7") }
    @Test func minBasic() throws { #expect(try MinFormulaEvaluator.evaluate(["3", "1", "7", "4"]) == "1") }
    @Test func productBasic() throws { #expect(try ProductFormulaEvaluator.evaluate(["2", "3", "4"]) == "24") }
    @Test func maxEmptyThrows() {
        #expect(throws: (any Error).self) { _ = try MaxFormulaEvaluator.evaluate([]) }
    }
    @Test func minNonNumericThrows() {
        #expect(throws: (any Error).self) { _ = try MinFormulaEvaluator.evaluate(["x"]) }
    }

    // MARK: - Single numeric
    @Test func absNegative() throws { #expect(try AbsFormulaEvaluator.evaluate("-5") == "5") }
    @Test func absPositive() throws { #expect(try AbsFormulaEvaluator.evaluate("3") == "3") }
    @Test func sqrtPerfect() throws { #expect(try SqrtFormulaEvaluator.evaluate("16") == "4") }
    @Test func intTruncates() throws { #expect(try IntFormulaEvaluator.evaluate("3.7") == "3") }
    @Test func intNegativeTruncates() throws { #expect(try IntFormulaEvaluator.evaluate("-3.7") == "-3") }
    @Test func signNegative() throws { #expect(try SignFormulaEvaluator.evaluate("-5") == "-1") }
    @Test func signZero() throws { #expect(try SignFormulaEvaluator.evaluate("0") == "0") }
    @Test func signPositive() throws { #expect(try SignFormulaEvaluator.evaluate("42") == "1") }
    @Test func evenRounds() throws {
        #expect(try EvenFormulaEvaluator.evaluate("3") == "4")
        #expect(try EvenFormulaEvaluator.evaluate("4") == "4")
        #expect(try EvenFormulaEvaluator.evaluate("3.1") == "4")
        #expect(try EvenFormulaEvaluator.evaluate("-3") == "-4")
    }
    @Test func oddRounds() throws {
        #expect(try OddFormulaEvaluator.evaluate("4") == "5")
        #expect(try OddFormulaEvaluator.evaluate("5") == "5")
        #expect(try OddFormulaEvaluator.evaluate("-4") == "-5")
    }
    @Test func factBasic() throws {
        #expect(try FactFormulaEvaluator.evaluate("0") == "1")
        #expect(try FactFormulaEvaluator.evaluate("5") == "120")
    }
    @Test func factNegativeThrows() {
        #expect(throws: (any Error).self) { _ = try FactFormulaEvaluator.evaluate("-1") }
    }
    @Test func lnE() throws {
        let r = Double(try LnFormulaEvaluator.evaluate(String(M_E))) ?? 0
        #expect(abs(r - 1.0) < 1e-9)
    }
    @Test func log10Ofhundred() throws {
        let r = Double(try Log10FormulaEvaluator.evaluate("100")) ?? 0
        #expect(abs(r - 2.0) < 1e-9)
    }
    @Test func expOne() throws {
        let r = Double(try ExpFormulaEvaluator.evaluate("1")) ?? 0
        #expect(abs(r - M_E) < 1e-9)
    }

    // MARK: - Two numeric
    @Test func modBasic() throws { #expect(try ModFormulaEvaluator.evaluate(dividend: "10", divisor: "3") == "1") }
    @Test func modZeroDivisor() {
        #expect(throws: (any Error).self) {
            _ = try ModFormulaEvaluator.evaluate(dividend: "5", divisor: "0")
        }
    }
    @Test func powerBasic() throws { #expect(try PowerFormulaEvaluator.evaluate(base: "2", exponent: "10") == "1024") }
    @Test func powerSquareRoot() throws { #expect(try PowerFormulaEvaluator.evaluate(base: "9", exponent: "0.5") == "3") }
    @Test func gcdBasic() throws { #expect(try GcdFormulaEvaluator.evaluate(a: 12, b: 8) == "4") }
    @Test func lcmBasic() throws { #expect(try LcmFormulaEvaluator.evaluate(a: 4, b: 6) == "12") }
    @Test func combinBasic() throws { #expect(try CombinFormulaEvaluator.evaluate(n: 5, k: 2) == "10") }
    @Test func combinKZero() throws { #expect(try CombinFormulaEvaluator.evaluate(n: 5, k: 0) == "1") }
    @Test func randbetweenRange() throws {
        for _ in 0..<50 {
            let s = try RandBetweenFormulaEvaluator.evaluate(low: 1, high: 10)
            let n = Int(s) ?? -1
            #expect((1...10).contains(n))
        }
    }

    // MARK: - Number + optional second arg
    @Test func roundDefault() throws { #expect(try RoundFormulaEvaluator.evaluate(value: "3.7", places: 0) == "4") }
    @Test func roundTwoPlaces() throws { #expect(try RoundFormulaEvaluator.evaluate(value: "3.14159", places: 2) == "3.14") }
    @Test func roundupAlwaysAway() throws {
        #expect(try RoundUpFormulaEvaluator.evaluate(value: "3.1", places: 0) == "4")
        #expect(try RoundUpFormulaEvaluator.evaluate(value: "-3.1", places: 0) == "-4")
    }
    @Test func rounddownTowardZero() throws {
        #expect(try RoundDownFormulaEvaluator.evaluate(value: "3.9", places: 0) == "3")
        #expect(try RoundDownFormulaEvaluator.evaluate(value: "-3.9", places: 0) == "-3")
    }
    @Test func ceilingBasic() throws {
        #expect(try CeilingFormulaEvaluator.evaluate(value: "4.1", factor: 1) == "5")
        #expect(try CeilingFormulaEvaluator.evaluate(value: "4.3", factor: 0.5) == "4.5")
    }
    @Test func floorBasic() throws {
        #expect(try FloorFormulaEvaluator.evaluate(value: "4.9", factor: 1) == "4")
        #expect(try FloorFormulaEvaluator.evaluate(value: "4.7", factor: 0.5) == "4.5")
    }
    @Test func logDefaultBaseIsTen() throws {
        let r = Double(try LogFormulaEvaluator.evaluate(value: "100", base: 10)) ?? 0
        #expect(abs(r - 2.0) < 1e-9)
    }
    @Test func logCustomBase() throws {
        let r = Double(try LogFormulaEvaluator.evaluate(value: "8", base: 2)) ?? 0
        #expect(abs(r - 3.0) < 1e-9)
    }

    // MARK: - Zero args: PI, RAND
    @Test func piConstant() {
        let r = Double(PiFormulaEvaluator.evaluate()) ?? 0
        #expect(abs(r - .pi) < 1e-9)
    }
    @Test func randRange() {
        for _ in 0..<50 {
            let r = Double(RandFormulaEvaluator.evaluate()) ?? -1
            #expect(r >= 0 && r < 1)
        }
    }

    // MARK: - Parser integration
    @Test func parserVariadic() throws {
        #expect(try FormulaParser.parse("=MAX(1,2,3)") == .max(args: ["1", "2", "3"]))
        #expect(try FormulaParser.parse("=MIN(1,2,3)") == .min(args: ["1", "2", "3"]))
        #expect(try FormulaParser.parse("=PRODUCT(2,3,4)") == .product(args: ["2", "3", "4"]))
    }
    @Test func parserSingle() throws {
        #expect(try FormulaParser.parse("=ABS(-5)") == .abs(value: "-5"))
        #expect(try FormulaParser.parse("=SQRT(16)") == .sqrt(value: "16"))
        #expect(try FormulaParser.parse("=INT(3.7)") == .intFn(value: "3.7"))
        #expect(try FormulaParser.parse("=SIGN(-5)") == .sign(value: "-5"))
        #expect(try FormulaParser.parse("=EVEN(3)") == .even(value: "3"))
        #expect(try FormulaParser.parse("=ODD(4)") == .odd(value: "4"))
        #expect(try FormulaParser.parse("=FACT(5)") == .fact(value: "5"))
        #expect(try FormulaParser.parse("=LN(1)") == .ln(value: "1"))
        #expect(try FormulaParser.parse("=LOG10(100)") == .log10Fn(value: "100"))
        #expect(try FormulaParser.parse("=EXP(1)") == .exp(value: "1"))
    }
    @Test func parserBinary() throws {
        #expect(try FormulaParser.parse("=MOD(10, 3)") == .mod(dividend: "10", divisor: "3"))
        #expect(try FormulaParser.parse("=POWER(2, 10)") == .power(base: "2", exponent: "10"))
        #expect(try FormulaParser.parse("=POW(2, 10)") == .power(base: "2", exponent: "10"), "POW is POWER")
        #expect(try FormulaParser.parse("=GCD(12, 8)") == .gcd(a: 12, b: 8))
        #expect(try FormulaParser.parse("=LCM(4, 6)") == .lcm(a: 4, b: 6))
        #expect(try FormulaParser.parse("=COMBIN(5, 2)") == .combin(n: 5, k: 2))
        #expect(try FormulaParser.parse("=RANDBETWEEN(1, 10)") == .randbetween(low: 1, high: 10))
    }
    @Test func parserRoundingDefaults() throws {
        #expect(try FormulaParser.parse("=ROUND(3.7)") == .round(value: "3.7", places: 0))
        #expect(try FormulaParser.parse("=ROUND(3.7, 2)") == .round(value: "3.7", places: 2))
        #expect(try FormulaParser.parse("=ROUNDUP(3.1)") == .roundup(value: "3.1", places: 0))
        #expect(try FormulaParser.parse("=ROUNDDOWN(3.9)") == .rounddown(value: "3.9", places: 0))
        #expect(try FormulaParser.parse("=CEILING(4.3)") == .ceiling(value: "4.3", factor: 1))
        #expect(try FormulaParser.parse("=CEILING(4.3, 0.5)") == .ceiling(value: "4.3", factor: 0.5))
        #expect(try FormulaParser.parse("=FLOOR(4.7)") == .floor(value: "4.7", factor: 1))
        #expect(try FormulaParser.parse("=LOG(100)") == .log(value: "100", base: 10))
        #expect(try FormulaParser.parse("=LOG(8, 2)") == .log(value: "8", base: 2))
    }
    @Test func parserZeroArgs() throws {
        #expect(try FormulaParser.parse("=PI()") == .pi)
        #expect(try FormulaParser.parse("=RAND()") == .rand)
        #expect(try FormulaParser.parse("=pi") == .pi)
        #expect(try FormulaParser.parse("=rand") == .rand)
    }

    // MARK: - Sync evaluator integration
    @Test func syncDispatch() throws {
        #expect(try FormulaSyncEvaluator.evaluate(.max(args: ["3", "1", "7"])) == "7")
        #expect(try FormulaSyncEvaluator.evaluate(.min(args: ["3", "1", "7"])) == "1")
        #expect(try FormulaSyncEvaluator.evaluate(.product(args: ["2", "3", "4"])) == "24")
        #expect(try FormulaSyncEvaluator.evaluate(.abs(value: "-5")) == "5")
        #expect(try FormulaSyncEvaluator.evaluate(.sqrt(value: "16")) == "4")
        #expect(try FormulaSyncEvaluator.evaluate(.intFn(value: "3.7")) == "3")
        #expect(try FormulaSyncEvaluator.evaluate(.sign(value: "-5")) == "-1")
        #expect(try FormulaSyncEvaluator.evaluate(.even(value: "3")) == "4")
        #expect(try FormulaSyncEvaluator.evaluate(.odd(value: "4")) == "5")
        #expect(try FormulaSyncEvaluator.evaluate(.fact(value: "5")) == "120")
        #expect(try FormulaSyncEvaluator.evaluate(.mod(dividend: "10", divisor: "3")) == "1")
        #expect(try FormulaSyncEvaluator.evaluate(.power(base: "2", exponent: "10")) == "1024")
        #expect(try FormulaSyncEvaluator.evaluate(.gcd(a: 12, b: 8)) == "4")
        #expect(try FormulaSyncEvaluator.evaluate(.lcm(a: 4, b: 6)) == "12")
        #expect(try FormulaSyncEvaluator.evaluate(.combin(n: 5, k: 2)) == "10")
        #expect(try FormulaSyncEvaluator.evaluate(.round(value: "3.7", places: 0)) == "4")
        #expect(try FormulaSyncEvaluator.evaluate(.roundup(value: "3.1", places: 0)) == "4")
        #expect(try FormulaSyncEvaluator.evaluate(.rounddown(value: "3.9", places: 0)) == "3")
        #expect(try FormulaSyncEvaluator.evaluate(.ceiling(value: "4.1", factor: 1)) == "5")
        #expect(try FormulaSyncEvaluator.evaluate(.floor(value: "4.9", factor: 1)) == "4")
        let logHundred = Double(try FormulaSyncEvaluator.evaluate(.log(value: "100", base: 10))) ?? 0
        #expect(abs(logHundred - 2.0) < 1e-9)
        let piVal = Double(try FormulaSyncEvaluator.evaluate(.pi)) ?? 0
        #expect(abs(piVal - .pi) < 1e-9)
        let randVal = Double(try FormulaSyncEvaluator.evaluate(.rand)) ?? -1
        #expect(randVal >= 0 && randVal < 1)
    }

    // MARK: - Registry
    @Test func registry() {
        for n in ["max", "min", "product", "abs", "sqrt", "int", "sign", "even",
                  "odd", "fact", "ln", "log10", "exp", "mod", "power", "pow",
                  "gcd", "lcm", "combin", "randbetween", "round", "roundup",
                  "rounddown", "ceiling", "floor", "log", "pi", "rand"] {
            #expect(FormulaRegistry.definition(forFunctionName: n) != nil, "missing: \(n)")
        }
    }
}
