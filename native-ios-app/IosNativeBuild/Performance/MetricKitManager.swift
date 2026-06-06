import MetricKit
import os.log

/// MetricKit subscriber for collecting production performance telemetry.
/// Payloads are delivered ~24h after app use; exported as JSON to Documents directory.
class MetricKitManager: NSObject {
    @MainActor static let shared = MetricKitManager()

    private let logger = Logger(
        subsystem: "com.amit.IosNativeBuild",
        category: "MetricKit"
    )

    private override init() {
        super.init()
    }

    @MainActor
    func startReceiving() {
        MXMetricManager.shared.add(self)
        logger.info("MetricKit subscriber registered")
    }

    @MainActor
    func stopReceiving() {
        MXMetricManager.shared.remove(self)
    }
}

extension MetricKitManager: MXMetricManagerSubscriber {
    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            let jsonData = payload.jsonRepresentation()
            let logger = Logger(subsystem: "com.amit.IosNativeBuild", category: "MetricKit")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                logger.info("MetricKit payload: \(jsonString.prefix(500))")
            }
            Task { @MainActor in
                self.savePayload(jsonData)
            }
        }
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let jsonData = payload.jsonRepresentation()
            let logger = Logger(subsystem: "com.amit.IosNativeBuild", category: "MetricKit")
            logger.info("MetricKit diagnostic payload received")
            Task { @MainActor in
                self.savePayload(jsonData, prefix: "diagnostic")
            }
        }
    }

    @MainActor
    private func savePayload(_ data: Data, prefix: String = "metric") {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "\(prefix)_\(formatter.string(from: Date())).json"

        if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = docsDir.appendingPathComponent(filename)
            try? data.write(to: url)
            logger.info("MetricKit payload saved to \(url.path)")
        }
    }
}
