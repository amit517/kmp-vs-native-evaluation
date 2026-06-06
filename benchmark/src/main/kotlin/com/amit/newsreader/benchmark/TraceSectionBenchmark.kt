package com.amit.newsreader.benchmark

import androidx.benchmark.macro.CompilationMode
import androidx.benchmark.macro.ExperimentalMetricApi
import androidx.benchmark.macro.FrameTimingMetric
import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.TraceSectionMetric
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Direction
import androidx.test.uiautomator.Until
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
@OptIn(ExperimentalMetricApi::class)
class TraceSectionBenchmark {

    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun networkToDatabase() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(
            TraceSectionMetric("NewsRepo.getArticles"),
            TraceSectionMetric("NewsRepo.networkFetch"),
            TraceSectionMetric("LocalDS.insertArticles")
        ),
        iterations = 30,
        startupMode = StartupMode.COLD,
        compilationMode = CompilationMode.Full(),
    ) {
        pressHome()
        startActivityAndWait()
        waitForArticleList()
    }

    @Test
    fun categoryFilterPerformance() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(TraceSectionMetric("NewsRepo.getArticles")),
        iterations = 50,
        startupMode = StartupMode.WARM,
        compilationMode = CompilationMode.Full(),
        setupBlock = {
            pressHome()
            startActivityAndWait()
            waitForArticleList()
        }
    ) {
        val technologyChip = device.findObject(By.res("category_chip_TECHNOLOGY"))
        technologyChip?.click()
        device.waitForIdle()
        val allChip = device.findObject(By.res("category_chip_all"))
        allChip?.click()
        device.waitForIdle()
    }

    @Test
    fun searchArticlesPerformance() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(TraceSectionMetric("NewsRepo.searchArticles")),
        iterations = 50,
        startupMode = StartupMode.WARM,
        compilationMode = CompilationMode.Full(),
        setupBlock = {
            pressHome()
            startActivityAndWait()
            waitForArticleList()
        }
    ) {
        val searchIcon = device.findObject(By.desc("Search"))
        searchIcon?.click()
        device.waitForIdle()
        val searchField = device.findObject(By.res("search_field"))
        searchField?.text = "technology"
        device.waitForIdle()
    }

    @Test
    fun imageLoadingPerformance() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(FrameTimingMetric()),
        iterations = 30,
        startupMode = StartupMode.WARM,
        compilationMode = CompilationMode.Full(),
        setupBlock = {
            pressHome()
            startActivityAndWait()
            device.wait(Until.hasObject(By.res("article_list")), 15_000)
        }
    ) {
        val list = device.findObject(By.scrollable(true))
        list.setGestureMargin(device.displayWidth / 5)
        repeat(3) {
            list.scroll(Direction.DOWN, 0.8f)
            device.waitForIdle()
        }
    }
}
