package com.amit.newsreader.benchmark

import androidx.benchmark.macro.MacrobenchmarkScope
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Until

const val PACKAGE_NAME = "com.amit.newsreader"

fun MacrobenchmarkScope.waitForArticleList(timeoutMs: Long = 15_000) {
    device.wait(Until.hasObject(By.res("article_list")), timeoutMs)
}

fun MacrobenchmarkScope.waitForLoadingComplete(timeoutMs: Long = 15_000) {
    device.wait(Until.gone(By.res("loading_indicator")), timeoutMs)
}
