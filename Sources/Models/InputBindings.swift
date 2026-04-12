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

    /// Substitute every `@name` token in `source` with its bound value.
    /// Unknown names are left unchanged. `@` followed by non-identifier
    /// characters is left alone. Matching is case-insensitive.
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
                // Read an identifier: [a-zA-Z_][a-zA-Z0-9_-]*
                var j = i + 1
                while j < chars.count, (chars[j].isLetter || chars[j].isNumber || chars[j] == "_" || chars[j] == "-") {
                    j += 1
                }
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
    static func references(in source: String) -> Set<String> {
        var out: Set<String> = []
        let chars = Array(source)
        var i = 0
        while i < chars.count {
            if chars[i] == "@" {
                var j = i + 1
                while j < chars.count, (chars[j].isLetter || chars[j].isNumber || chars[j] == "_" || chars[j] == "-") {
                    j += 1
                }
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
