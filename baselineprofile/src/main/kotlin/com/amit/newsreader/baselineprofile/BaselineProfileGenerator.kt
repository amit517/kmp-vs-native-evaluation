package com.amit.newsreader.baselineprofile

import androidx.benchmark.macro.junit4.BaselineProfileRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Direction
import androidx.test.uiautomator.Until
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class BaselineProfileGenerator {

    @get:Rule
    val rule = BaselineProfileRule()

    @Test
    fun generateBaselineProfile() = rule.collect(
        packageName = "com.amit.newsreader"
    ) {
        pressHome()
        startActivityAndWait()

        // Wait for content
        device.wait(Until.hasObject(By.res("article_list")), 15_000)

        // Scroll through articles
        val list = device.findObject(By.res("article_list"))
        list?.let {
            it.setGestureMargin(device.displayWidth / 5)
            repeat(3) { _ -> it.fling(Direction.DOWN) }
            repeat(2) { _ -> it.fling(Direction.UP) }
        }

        // Category filter
        device.findObject(By.res("category_chip_TECHNOLOGY"))?.click()
        device.waitForIdle()
        device.wait(Until.hasObject(By.res("article_list")), 10_000)

        device.findObject(By.res("category_chip_all"))?.click()
        device.waitForIdle()

        // Navigate to article detail
        val firstCard = device.findObject(By.resContains("article_card_"))
        firstCard?.click()
        device.waitForIdle()
        device.pressBack()
        device.waitForIdle()

        // Navigate to favorites
        device.findObject(By.desc("Favorites"))?.click()
        device.waitForIdle()
        device.pressBack()
        device.waitForIdle()
    }
}
