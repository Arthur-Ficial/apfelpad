import Foundation
#if canImport(SQLite3)
import SQLite3
#endif

/// Persistent formula cache backed by raw C SQLite3.
/// Single table keyed by `CacheKey.hash`.
final class SQLiteFormulaCache: FormulaCache, @unchecked Sendable {
    private let db: OpaquePointer
    private let queue = DispatchQueue(label: "apfelpad.cache", qos: .userInitiated)
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(path: String) throws {
        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(path, &dbPointer, flags, nil) == SQLITE_OK,
              let db = dbPointer else {
            let msg = dbPointer.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(dbPointer)
            throw CacheError.openFailed(msg)
        }
        self.db = db
        sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA synchronous=NORMAL", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA cache_size=-8000", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA temp_store=MEMORY", nil, nil, nil)
        try createTables()
    }

    deinit { sqlite3_close(db) }

    static func defaultPath() -> String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        let dir = appSupport.appendingPathComponent("apfelpad/cache")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("default.sqlite").path
    }

    // MARK: - Schema

    private func createTables() throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS formulas (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            created_at REAL NOT NULL
        );
        """
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw CacheError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    // MARK: - Bridge to async

    private func onQueue<T: Sendable>(_ work: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do { continuation.resume(returning: try work()) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    // MARK: - FormulaCache

    func get(key: CacheKey) async throws -> String? {
        let hash = key.hash
        return try await onQueue {
            try self.selectValue(forKey: hash)
        }
    }

    func set(key: CacheKey, value: String) async throws {
        let hash = key.hash
        try await onQueue {
            try self.upsertValue(hash: hash, value: value)
        }
    }

    func delete(key: CacheKey) async throws {
        let hash = key.hash
        try await onQueue {
            try self.deleteRow(hash: hash)
        }
    }

    // MARK: - Private helpers (all run on `queue`)

    private func selectValue(forKey hash: String) throws -> String? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT value FROM formulas WHERE key = ?", -1, &stmt, nil) == SQLITE_OK else {
            throw CacheError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, hash, -1, SQLITE_TRANSIENT)
        let rc = sqlite3_step(stmt)
        if rc == SQLITE_ROW {
            return String(cString: sqlite3_column_text(stmt, 0))
        }
        if rc == SQLITE_DONE {
            return nil
        }
        throw CacheError.queryFailed(String(cString: sqlite3_errmsg(db)))
    }

    private func upsertValue(hash: String, value: String) throws {
        let sql = """
        INSERT INTO formulas (key, value, created_at) VALUES (?, ?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value, created_at = excluded.created_at
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw CacheError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, hash, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, value, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 3, Date().timeIntervalSince1970)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw CacheError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    private func deleteRow(hash: String) throws {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM formulas WHERE key = ?", -1, &stmt, nil) == SQLITE_OK else {
            throw CacheError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, hash, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw CacheError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
    }
}

enum CacheError: LocalizedError {
    case openFailed(String)
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .openFailed(let msg): return "Cache database open failed: \(msg)"
        case .queryFailed(let msg): return "Cache query failed: \(msg)"
        }
    }
}
