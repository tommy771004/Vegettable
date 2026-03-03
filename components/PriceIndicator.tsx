import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { PriceLevel } from '@/types';
import { Colors, BorderRadius, FontSize, Spacing } from '@/constants/theme';
import { PRICE_LEVEL_LABELS } from '@/constants/categories';

interface PriceIndicatorProps {
  level: PriceLevel;
  compact?: boolean;
}

export function PriceIndicator({ level, compact = false }: PriceIndicatorProps) {
  const color = Colors.priceLevel[level];
  const bgColor = Colors.priceLevelBg[level];
  const label = PRICE_LEVEL_LABELS[level];

  if (compact) {
    return (
      <View style={[styles.dot, { backgroundColor: color }]} />
    );
  }

  return (
    <View style={[styles.badge, { backgroundColor: bgColor }]}>
      <View style={[styles.badgeDot, { backgroundColor: color }]} />
      <Text style={[styles.badgeText, { color }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  dot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.xs,
    borderRadius: BorderRadius.pill,
    gap: 4,
  },
  badgeDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  badgeText: {
    fontSize: FontSize.xs,
    fontWeight: '600',
  },
});
