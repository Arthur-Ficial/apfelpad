import Foundation

/// Document-level storage for all =input variable values. Keys are
/// case-insensitive (we store the lowercased name). Supports @name
/// substitution inside formula sources.
///
/// This is the reactive state backbone: every change triggers a walk of
/// every span and re-evaluation of the ones whose source contains
/// `@name`. The dependency graph is implicit — we just re-check sources.
final class InputBindings: @unchecked Sendable {
    private var store: [String: String] = [:]
    private let lock = NSLock()

    func set(_ name: String, to value: String) {
        lock.lock()
        store[name.lowercased()] = value
        lock.unlock()
    }

    func value(for name: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return store[name.lowercased()]
    }

    func remove(_ name: String) {
        lock.lock()
        store.removeValue(forKey: name.lowercased())
        lock.unlock()
    }

    var names: Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return Set(store.keys)
    }

    /// A valid `@name` reference at position `i` requires that the
    /// character immediately before `@` is NOT alphanumeric (or `.`) —
    /// this filters out email addresses like `test@test.com` and
    /// file-like tokens `foo.@bar`.
    private static func isReferenceStart(chars: [Character], at i: Int) -> Bool {
        guard i > 0 else { return true }
        let prev = chars[i - 1]
        if prev.isLetter || prev.isNumber { return false }
        if prev == "." { return false }
        return true
    }

    /// `@#name` is a section reference (for =ref), not an input variable.
    private static func isSectionRef(chars: [Character], at i: Int) -> Bool {
        i + 1 < chars.count && chars[i + 1] == "#"
    }

    /// Read a `[A-Za-z0-9_-]+` identifier starting at position `after` and
    /// return the new index (exclusive end).
    private static func readIdentifier(chars: [Character], after: Int) -> Int {
        var j = after
        while j < chars.count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" || chars[j] == "-" {
            j += 1
        }
        return j
    }

    /// Substitute every `@name` token in `source` with its bound value.
    /// Unknown names are left unchanged. Skips:
    ///   - `@#name`   — section references
    ///   - `word@word`— email-like tokens (alphanumeric or `.` before `@`)
    func substitute(in source: String) -> String {
        lock.lock()
        let snapshot = store
        lock.unlock()
        if snapshot.isEmpty { return source }

        var out = ""
        let chars = Array(source)
        var i = 0
        while i < chars.count {
            if chars[i] == "@" {
                if Self.isSectionRef(chars: chars, at: i) {
                    out.append(chars[i])
                    i += 1
                    continue
                }
                if !Self.isReferenceStart(chars: chars, at: i) {
                    out.append(chars[i])
                    i += 1
                    continue
                }
                let j = Self.readIdentifier(chars: chars, after: i + 1)
                let name = String(chars[(i+1)..<j]).lowercased()
                if !name.isEmpty, let value = snapshot[name] {
                    out.append(value)
                    i = j
                    continue
                }
            }
            out.append(chars[i])
            i += 1
        }
        return out
    }

    /// Return the set of `@name` references in a formula source (lowercased).
    /// Applies the same skip rules as `substitute`.
    static func references(in source: String) -> Set<String> {
        var out: Set<String> = []
        let chars = Array(source)
        var i = 0
        while i < chars.count {
            if chars[i] == "@" {
                if isSectionRef(chars: chars, at: i) {
                    i += 2
                    continue
                }
                if !isReferenceStart(chars: chars, at: i) {
                    i += 1
                    continue
                }
                let j = readIdentifier(chars: chars, after: i + 1)
                let name = String(chars[(i+1)..<j]).lowercased()
                if !name.isEmpty { out.insert(name) }
                i = j
            } else {
                i += 1
            }
        }
        return out
    }
}
