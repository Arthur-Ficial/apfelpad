import Foundation

/// =IFS(cond1, value1, [cond2, value2, ...]) — return the value matching the
/// first truthy condition. Throws if no condition is truthy or args are odd.
enum IfsFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case oddArgCount
        case noTruthyCondition

        var errorDescription: String? {
            switch self {
            case .oddArgCount:
                return "IFS: arguments must come in condition/value pairs"
            case .noTruthyCondition:
                return "IFS: no condition was truthy"
            }
        }
    }

    static func evaluate(args: [String]) throws -> String {
        guard args.count >= 2 else { throw Error.oddArgCount }
        guard args.count % 2 == 0 else { throw Error.oddArgCount }
        var i = 0
        while i < args.count {
            if IfFormulaEvaluator.isTruthy(args[i]) {
                return args[i + 1]
            }
            i += 2
        }
        throw Error.noTruthyCondition
    }
}
