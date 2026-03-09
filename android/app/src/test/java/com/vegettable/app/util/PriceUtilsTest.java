package com.vegettable.app.util;

import org.junit.Test;
import static org.junit.Assert.*;

public class PriceUtilsTest {

    @Test
    public void convertToCatty_100kg_Returns60() {
        assertEquals(60.0, PriceUtils.convertToCatty(100.0), 0.001);
    }

    @Test
    public void convertToCatty_0kg_Returns0() {
        assertEquals(0.0, PriceUtils.convertToCatty(0.0), 0.001);
    }

    @Test
    public void estimateRetailPrice_100_Returns250() {
        assertEquals(250.0, PriceUtils.estimateRetailPrice(100.0), 0.001);
    }

    @Test
    public void formatPrice_Integer_ReturnsNoDecimal() {
        assertEquals("100", PriceUtils.formatPrice(100.0));
    }

    @Test
    public void formatPrice_Decimal_ReturnsOneDecimalPlace() {
        assertEquals("100.5", PriceUtils.formatPrice(100.5));
    }

    @Test
    public void formatPrice_Zero_ReturnsZero() {
        assertEquals("0", PriceUtils.formatPrice(0.0));
    }

    @Test
    public void getPriceLevelLabel_VeryCheap_ReturnsChinese() {
        assertEquals("當令便宜", PriceUtils.getPriceLevelLabel("very-cheap"));
    }

    @Test
    public void getPriceLevelLabel_Cheap_ReturnsChinese() {
        assertEquals("相對便宜", PriceUtils.getPriceLevelLabel("cheap"));
    }

    @Test
    public void getPriceLevelLabel_Normal_ReturnsChinese() {
        assertEquals("略偏貴", PriceUtils.getPriceLevelLabel("normal"));
    }

    @Test
    public void getPriceLevelLabel_Expensive_ReturnsChinese() {
        assertEquals("相對偏貴", PriceUtils.getPriceLevelLabel("expensive"));
    }

    @Test
    public void getPriceLevelLabel_Null_ReturnsEmpty() {
        assertEquals("", PriceUtils.getPriceLevelLabel(null));
    }

    @Test
    public void getTrendArrow_Up_ReturnsUpArrow() {
        assertEquals("↑", PriceUtils.getTrendArrow("up"));
    }

    @Test
    public void getTrendArrow_Down_ReturnsDownArrow() {
        assertEquals("↓", PriceUtils.getTrendArrow("down"));
    }

    @Test
    public void getTrendArrow_Stable_ReturnsRightArrow() {
        assertEquals("→", PriceUtils.getTrendArrow("stable"));
    }

    @Test
    public void getTrendArrow_Null_ReturnsRightArrow() {
        assertEquals("→", PriceUtils.getTrendArrow(null));
    }
}