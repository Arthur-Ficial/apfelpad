import Foundation

/// =TEXT(value, [format]) — format a value as a string. Supports a small
/// curated subset of Google Sheets format codes:
///
/// - empty / no format → value as-is
/// - "0" → integer (rounded)
/// - "0.0", "0.00", ... → fixed-decimal (count the `0`s after `.`)
/// - "0%" → percentage (value * 100, append "%")
///
/// Any other format string falls back to value as-is.
enum TextFormulaEvaluator {
    static func evaluate(value: String, format: String) throws -> String {
        let fmt = format.trimmingCharacters(in: .whitespacesAndNewlines)
        if fmt.isEmpty { return value }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let n = Double(trimmed) else { return value }
        if fmt == "0" {
            return String(Int(n.rounded()))
        }
        if fmt == "0%" {
            return "\(Int((n * 100).rounded()))%"
        }
        if fmt.hasPrefix("0.") {
            let decimals = fmt.dropFirst(2).count
            return String(format: "%.\(decimals)f", n)
        }
        return value
    }
}
