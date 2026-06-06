import Foundation

enum BenchmarkExporter {

    static func exportToCSV(results: [BenchmarkResult], filename: String) throws -> URL {
        var csv = "platform,metric,iteration,value,unit,timestamp,device,os_version,build_type\n"
        for r in results {
            csv += "\(r.platform),\(r.metric),\(r.iteration),\(r.value),\(r.unit),\(r.timestamp),\(r.device),\(r.osVersion),\(r.buildType)\n"
        }
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func exportToJSON(results: [BenchmarkResult], filename: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(results)
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }

    static func statistics(for values: [Double]) -> (mean: Double, median: Double, stdDev: Double, min: Double, max: Double, p95: Double, p99: Double) {
        guard !values.isEmpty else { return (0, 0, 0, 0, 0, 0, 0) }
        let sorted = values.sorted()
        let count = Double(sorted.count)
        let mean = sorted.reduce(0, +) / count
        let median: Double = sorted.count % 2 == 0
            ? (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2.0
            : sorted[sorted.count / 2]
        let variance = sorted.reduce(0) { $0 + pow($1 - mean, 2) } / count
        let stdDev = sqrt(variance)
        let p95Index = min(Int(ceil(0.95 * count)) - 1, sorted.count - 1)
        let p99Index = min(Int(ceil(0.99 * count)) - 1, sorted.count - 1)
        return (mean: mean, median: median, stdDev: stdDev, min: sorted.first!, max: sorted.last!, p95: sorted[p95Index], p99: sorted[p99Index])
    }
}
