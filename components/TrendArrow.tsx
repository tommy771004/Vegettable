import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { PriceTrend } from '@/types';
import { Colors, FontSize } from '@/constants/theme';

interface TrendArrowProps {
  trend: PriceTrend;
  showLabel?: boolean;
  size?: number;
}

const trendConfig = {
  up: { icon: 'arrow-up' as const, color: Colors.trend.up, label: '漲' },
  down: { icon: 'arrow-down' as const, color: Colors.trend.down, label: '跌' },
  stable: { icon: 'remove' as const, color: Colors.trend.stable, label: '平' },
};

export function TrendArrow({ trend, showLabel = false, size = 14 }: TrendArrowProps) {
  const config = trendConfig[trend];

  return (
    <View style={styles.container}>
      <Ionicons name={config.icon} size={size} color={config.color} />
      {showLabel && (
        <Text style={[styles.label, { color: config.color }]}>{config.label}</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  label: {
    fontSize: FontSize.xs,
    fontWeight: '600',
  },
});
