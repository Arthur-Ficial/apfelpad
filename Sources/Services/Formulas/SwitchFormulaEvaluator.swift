import Foundation

/// =SWITCH(expr, case1, value1, [case2, value2, ...], [default])
///
/// Tests `expr` against each `case` argument and returns the matching `value`.
/// If args after `expr` are odd, the trailing argument is the default.
/// If even, no default — throw when nothing matches.
enum SwitchFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case noMatchAndNoDefault
        case malformedArguments

        var errorDescription: String? {
            switch self {
            case .noMatchAndNoDefault:
                return "SWITCH: no case matched and no default supplied"
            case .malformedArguments:
                return "SWITCH: at least an expression and one case/value pair are required"
            }
        }
    }

    static func evaluate(args: [String]) throws -> String {
        guard args.count >= 3 else { throw Error.malformedArguments }
        let expr = args[0]
        let rest = Array(args.dropFirst())
        // Walk case/value pairs.
        var i = 0
        while i + 1 < rest.count {
            if rest[i] == expr {
                return rest[i + 1]
            }
            i += 2
        }
        // Odd-length rest → trailing default.
        if rest.count % 2 == 1 {
            return rest.last ?? ""
        }
        throw Error.noMatchAndNoDefault
    }
}
