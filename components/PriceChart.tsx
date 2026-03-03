import React from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { DailyPrice, MonthlyPrice } from '@/types';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { formatShortDate } from '@/utils/date';

const CHART_HEIGHT = 160;
const BAR_WIDTH = 28;

interface DailyChartProps {
  data: DailyPrice[];
  title: string;
}

export function DailyChart({ data, title }: DailyChartProps) {
  if (data.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyText}>暫無資料</Text>
      </View>
    );
  }

  const maxPrice = Math.max(...data.map((d) => d.avgPrice));
  const minPrice = Math.min(...data.map((d) => d.avgPrice));
  const range = maxPrice - minPrice || 1;

  return (
    <View style={styles.chartContainer}>
      <Text style={styles.chartTitle}>{title}</Text>
      <View style={styles.chart}>
        {data.map((item, index) => {
          const height = ((item.avgPrice - minPrice) / range) * (CHART_HEIGHT - 40) + 30;
          const isLatest = index === data.length - 1;

          return (
            <View key={item.date} style={styles.barColumn}>
              <Text style={[styles.barValue, isLatest && styles.barValueLatest]}>
                {item.avgPrice.toFixed(1)}
              </Text>
              <View
                style={[
                  styles.bar,
                  {
                    height,
                    backgroundColor: isLatest
                      ? Colors.primary
                      : Colors.primaryLight + '60',
                  },
                ]}
              />
              <Text style={styles.barLabel}>{formatShortDate(item.date)}</Text>
            </View>
          );
        })}
      </View>
    </View>
  );
}

interface MonthlyChartProps {
  data: MonthlyPrice[];
  title: string;
}

export function MonthlyChart({ data, title }: MonthlyChartProps) {
  if (data.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyText}>暫無資料</Text>
      </View>
    );
  }

  const maxPrice = Math.max(...data.map((d) => d.avgPrice));
  const minPrice = Math.min(...data.map((d) => d.avgPrice));
  const range = maxPrice - minPrice || 1;
  const screenWidth = Dimensions.get('window').width;
  const barWidth = Math.max(8, Math.min(BAR_WIDTH, (screenWidth - 80) / data.length - 4));

  return (
    <View style={styles.chartContainer}>
      <Text style={styles.chartTitle}>{title}</Text>
      <View style={styles.monthlyChart}>
        {data.map((item, index) => {
          const height = ((item.avgPrice - minPrice) / range) * (CHART_HEIGHT - 40) + 20;
          const isCurrentMonth =
            index === data.length - 1;

          return (
            <View key={item.month} style={[styles.barColumn, { width: barWidth + 4 }]}>
              <View
                style={[
                  styles.monthBar,
                  {
                    height,
                    width: barWidth,
                    backgroundColor: isCurrentMonth
                      ? Colors.primary
                      : Colors.primaryLight + '40',
                  },
                ]}
              />
              {index % Math.ceil(data.length / 8) === 0 && (
                <Text style={styles.monthLabel}>{item.month}</Text>
              )}
            </View>
          );
        })}
      </View>
      <View style={styles.priceRange}>
        <Text style={styles.rangeText}>最低 ${minPrice.toFixed(1)}</Text>
        <Text style={styles.rangeText}>最高 ${maxPrice.toFixed(1)}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  chartContainer: {
    marginVertical: Spacing.sm,
  },
  chartTitle: {
    fontSize: FontSize.md,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: Spacing.md,
  },
  chart: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-around',
    height: CHART_HEIGHT,
    paddingBottom: Spacing.xl,
  },
  monthlyChart: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'flex-start',
    height: CHART_HEIGHT,
    paddingBottom: Spacing.xl,
    flexWrap: 'nowrap',
  },
  barColumn: {
    alignItems: 'center',
    gap: 4,
  },
  barValue: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
    fontWeight: '500',
  },
  barValueLatest: {
    color: Colors.primary,
    fontWeight: '700',
  },
  bar: {
    width: BAR_WIDTH,
    borderRadius: BorderRadius.sm,
    minHeight: 4,
  },
  monthBar: {
    borderRadius: 4,
    minHeight: 4,
  },
  barLabel: {
    fontSize: 9,
    color: Colors.textTertiary,
    position: 'absolute',
    bottom: -16,
  },
  monthLabel: {
    fontSize: 8,
    color: Colors.textTertiary,
    position: 'absolute',
    bottom: -16,
    width: 40,
    textAlign: 'center',
  },
  priceRange: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: Spacing.sm,
  },
  rangeText: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
  },
  emptyContainer: {
    height: 100,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    fontSize: FontSize.md,
    color: Colors.textTertiary,
  },
});
