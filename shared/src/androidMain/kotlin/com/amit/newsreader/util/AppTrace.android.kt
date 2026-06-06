package com.amit.newsreader.util

import android.os.Trace

actual object AppTrace {
    actual fun beginSection(label: String) {
        Trace.beginSection(label)
    }

    actual fun endSection() {
        Trace.endSection()
    }
}
