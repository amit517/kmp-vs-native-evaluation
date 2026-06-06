import os.signpost

/// Centralized performance monitoring using os_signpost.
/// Integrates with Xcode Instruments for detailed profiling.
/// All `name` parameters must be StaticString (compile-time string literals).
enum PerformanceMonitor {

    // MARK: - Category Logs

    static let networkLog = OSLog(
        subsystem: "com.amit.IosNativeBuild",
        category: "Network"
    )

    static let databaseLog = OSLog(
        subsystem: "com.amit.IosNativeBuild",
        category: "Database"
    )

    static let uiLog = OSLog(
        subsystem: "com.amit.IosNativeBuild",
        category: "UI"
    )

    static let generalLog = OSLog(
        subsystem: "com.amit.IosNativeBuild",
        category: "Performance"
    )

    // MARK: - Signpost Interval API

    /// Begin a signpost interval. Returns the signpost ID for pairing with end.
    static func beginInterval(
        _ name: StaticString,
        log: OSLog = PerformanceMonitor.generalLog
    ) -> OSSignpostID {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        return id
    }

    /// End a signpost interval.
    static func endInterval(
        _ name: StaticString,
        log: OSLog = PerformanceMonitor.generalLog,
        id: OSSignpostID
    ) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }

    /// Measure a synchronous block with signpost.
    static func measure<T>(
        _ name: StaticString,
        log: OSLog = PerformanceMonitor.generalLog,
        _ block: () throws -> T
    ) rethrows -> T {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        let result = try block()
        os_signpost(.end, log: log, name: name, signpostID: id)
        return result
    }

    /// Measure an async operation with signpost.
    static func measureAsync<T>(
        _ name: StaticString,
        log: OSLog = PerformanceMonitor.generalLog,
        _ block: () async throws -> T
    ) async rethrows -> T {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        let result = try await block()
        os_signpost(.end, log: log, name: name, signpostID: id)
        return result
    }

    /// Emit a single signpost event (not an interval).
    static func event(
        _ name: StaticString,
        log: OSLog = PerformanceMonitor.generalLog
    ) {
        os_signpost(.event, log: log, name: name)
    }
}
