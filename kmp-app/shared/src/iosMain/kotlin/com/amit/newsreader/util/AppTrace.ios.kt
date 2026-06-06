package com.amit.newsreader.util

actual object AppTrace {
    actual fun beginSection(label: String) { /* no-op on iOS — use Instruments instead */ }
    actual fun endSection() { /* no-op */ }
}
