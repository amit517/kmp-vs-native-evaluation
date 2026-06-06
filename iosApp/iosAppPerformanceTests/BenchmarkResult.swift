import Foundation
import UIKit

struct BenchmarkResult: Codable {
    let platform: String
    let metric: String
    let iteration: Int
    let value: Double
    let unit: String
    let timestamp: String
    let device: String
    let osVersion: String
    let buildType: String

    static func create(
        metric: String,
        iteration: Int,
        value: Double,
        unit: String
    ) -> BenchmarkResult {
        BenchmarkResult(
            platform: "kmp_ios",
            metric: metric,
            iteration: iteration,
            value: value,
            unit: unit,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            device: deviceModel(),
            osVersion: UIDevice.current.systemVersion,
            buildType: "release"
        )
    }

    private static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
    }
}
