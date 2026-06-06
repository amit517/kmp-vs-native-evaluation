package com.amit.newsreader.util

/**
 * Multiplatform trace utility for performance benchmarking.
 * Android: delegates to android.os.Trace (captured by Macrobenchmark TraceSectionMetric)
 * iOS: no-op (iOS uses Instruments/signposts instead)
 */
expect object AppTrace {
    fun beginSection(label: String)
    fun endSection()
}

inline fun <T> appTrace(label: String, block: () -> T): T {
    AppTrace.beginSection(label)
    try {
        return block()
    } finally {
        AppTrace.endSection()
    }
}

suspend inline fun <T> appTraceSuspend(label: String, block: () -> T): T {
    AppTrace.beginSection(label)
    try {
        return block()
    } finally {
        AppTrace.endSection()
    }
}
