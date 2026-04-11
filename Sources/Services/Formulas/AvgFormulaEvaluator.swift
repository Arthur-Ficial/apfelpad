import Foundation

enum AvgFormulaEvaluator {
    static func evaluate(_ args: [String]) throws -> String {
        if args.isEmpty { return "0" }
        var total: Double = 0
        for raw in args {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let n = Double(t) else {
                throw SumFormulaEvaluator.Error.notANumber(t)
            }
            total += n
        }
        let mean = total / Double(args.count)
        return SumFormulaEvaluator.format(mean)
    }
}
