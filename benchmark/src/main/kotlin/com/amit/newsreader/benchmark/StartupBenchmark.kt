package com.amit.newsreader.benchmark

import androidx.benchmark.macro.BaselineProfileMode
import androidx.benchmark.macro.CompilationMode
import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.StartupTimingMetric
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class StartupBenchmark {

    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun coldStartupFull() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(StartupTimingMetric()),
        iterations = 30,
        startupMode = StartupMode.COLD,
        compilationMode = CompilationMode.Full(),
    ) {
        pressHome()
        startActivityAndWait()
        waitForArticleList()
    }

    @Test
    fun coldStartupWithBaselineProfile() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(StartupTimingMetric()),
        iterations = 30,
        startupMode = StartupMode.COLD,
        compilationMode = CompilationMode.Partial(
            baselineProfileMode = BaselineProfileMode.Require
        ),
    ) {
        pressHome()
        startActivityAndWait()
        waitForArticleList()
    }

    @Test
    fun warmStartup() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(StartupTimingMetric()),
        iterations = 50,
        startupMode = StartupMode.WARM,
        compilationMode = CompilationMode.Full(),
    ) {
        pressHome()
        startActivityAndWait()
        waitForArticleList()
    }

    @Test
    fun hotStartup() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(StartupTimingMetric()),
        iterations = 50,
        startupMode = StartupMode.HOT,
        compilationMode = CompilationMode.Full(),
    ) {
        pressHome()
        startActivityAndWait()
        waitForArticleList()
    }
}
