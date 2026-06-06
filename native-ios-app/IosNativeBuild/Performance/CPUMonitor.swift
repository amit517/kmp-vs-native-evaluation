import Foundation

/// CPU usage monitor using Mach thread APIs.
/// Aggregates CPU usage across all threads in the current process.
struct CPUMonitor {

    struct CPUSnapshot {
        let totalUsagePercent: Double
        let threadCount: Int
        let timestamp: Date
    }

    /// Get current CPU usage percentage across all threads.
    static func currentCPUUsage() -> CPUSnapshot {
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)

        let result = task_threads(mach_task_self_, &threadsList, &threadsCount)

        guard result == KERN_SUCCESS, let threads = threadsList else {
            return CPUSnapshot(totalUsagePercent: 0, threadCount: 0, timestamp: Date())
        }

        var totalCPU: Double = 0

        for i in 0..<Int(threadsCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                    thread_info(
                        threads[i],
                        thread_flavor_t(THREAD_BASIC_INFO),
                        $0,
                        &threadInfoCount
                    )
                }
            }

            if infoResult == KERN_SUCCESS && threadInfo.flags & TH_FLAGS_IDLE == 0 {
                totalCPU += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE)
            }
        }

        vm_deallocate(
            mach_task_self_,
            vm_address_t(bitPattern: threads),
            vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
        )

        return CPUSnapshot(
            totalUsagePercent: totalCPU * 100,
            threadCount: Int(threadsCount),
            timestamp: Date()
        )
    }
}
