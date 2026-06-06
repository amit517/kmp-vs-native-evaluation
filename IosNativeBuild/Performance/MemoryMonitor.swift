import Foundation

/// Memory usage monitor using Mach kernel APIs.
/// Provides resident memory size for the current process.
struct MemoryMonitor {

    struct MemorySnapshot {
        let residentSize: UInt64       // bytes
        let residentSizePeak: UInt64   // bytes
        let timestamp: Date

        var residentSizeMB: Double { Double(residentSize) / 1_048_576.0 }
        var residentSizePeakMB: Double { Double(residentSizePeak) / 1_048_576.0 }
    }

    /// Get current memory usage snapshot.
    static func currentMemoryUsage() -> MemorySnapshot {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        if result == KERN_SUCCESS {
            return MemorySnapshot(
                residentSize: info.resident_size,
                residentSizePeak: info.resident_size_max,
                timestamp: Date()
            )
        }
        return MemorySnapshot(residentSize: 0, residentSizePeak: 0, timestamp: Date())
    }
}
