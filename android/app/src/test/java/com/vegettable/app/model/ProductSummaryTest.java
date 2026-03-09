package com.vegettable.app.model;

import org.junit.Test;
import static org.junit.Assert.*;

public class ProductSummaryTest {

    @Test
    public void productSummary_DefaultValues_AreNull() {
        ProductSummary summary = new ProductSummary();
        assertNull(summary.getCropCode());
        assertNull(summary.getCropName());
    }

    @Test
    public void dailyPrice_DefaultAvgPrice_IsZero() {
        DailyPrice dp = new DailyPrice();
        assertEquals(0.0, dp.getAvgPrice(), 0.001);
    }

    @Test
    public void monthlyPrice_DefaultAvgPrice_IsZero() {
        MonthlyPrice mp = new MonthlyPrice();
        assertEquals(0.0, mp.getAvgPrice(), 0.001);
    }

    @Test
    public void priceAlert_DefaultIsActive_IsFalse() {
        PriceAlert alert = new PriceAlert();
        assertFalse(alert.isActive());
    }
}