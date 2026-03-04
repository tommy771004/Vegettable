import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { GlassCard } from './GlassCard';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { PricePrediction } from '@/types';

interface Props {
  prediction: PricePrediction;
}

const DIRECTION_CONFIG = {
  up: { icon: 'trending-up', color: '#D32F2F', label: '預測上漲' },
  down: { icon: 'trending-down', color: '#2E7D32', label: '預測下跌' },
  stable: { icon: 'remove', color: '#757575', label: '預測持平' },
} as const;

export function PredictionCard({ prediction }: Props) {
  const config = DIRECTION_CONFIG[prediction.direction];

  return (
    <GlassCard style={styles.card}>
      <View style={styles.header}>
        <Ionicons name="analytics-outline" size={18} color={Colors.primary} />
        <Text style={styles.title}>AI 價格預測</Text>
      </View>

      <View style={styles.priceRow}>
        <View style={styles.priceItem}>
          <Text style={styles.priceLabel}>目前均價</Text>
          <Text style={styles.priceValue}>${prediction.currentPrice}</Text>
        </View>
        <Ionicons name="arrow-forward" size={20} color={Colors.textTertiary} />
        <View style={styles.priceItem}>
          <Text style={styles.priceLabel}>預測下週</Text>
          <Text style={[styles.priceValue, { color: config.color }]}>
            ${prediction.predictedPrice}
          </Text>
        </View>
      </View>

      <View style={styles.directionRow}>
        <Ionicons name={config.icon as any} size={18} color={config.color} />
        <Text style={[styles.directionText, { color: config.color }]}>
          {config.label} ({prediction.changePercent > 0 ? '+' : ''}{prediction.changePercent}%)
        </Text>
      </View>

      <View style={styles.confidenceRow}>
        <Text style={styles.confidenceLabel}>信心度</Text>
        <View style={styles.confidenceBarBg}>
          <View style={[styles.confidenceBar, {
            width: `${prediction.confidence}%`,
            backgroundColor: prediction.confidence > 60 ? Colors.primary : Colors.trend.up,
          }]} />
        </View>
        <Text style={styles.confidenceValue}>{prediction.confidence}%</Text>
      </View>

      <Text style={styles.reasoning}>{prediction.reasoning}</Text>
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  card: { marginHorizontal: 0, marginTop: Spacing.md },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.md,
  },
  title: { fontSize: FontSize.md, fontWeight: '600', color: Colors.text },
  priceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.lg,
    marginBottom: Spacing.md,
  },
  priceItem: { alignItems: 'center' },
  priceLabel: { fontSize: FontSize.xs, color: Colors.textTertiary, marginBottom: 2 },
  priceValue: { fontSize: FontSize.xl, fontWeight: '700', color: Colors.text },
  directionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.xs,
    marginBottom: Spacing.md,
  },
  directionText: { fontSize: FontSize.md, fontWeight: '600' },
  confidenceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.md,
  },
  confidenceLabel: { fontSize: FontSize.sm, color: Colors.textSecondary, width: 50 },
  confidenceBarBg: {
    flex: 1,
    height: 8,
    backgroundColor: 'rgba(0,0,0,0.06)',
    borderRadius: 4,
    overflow: 'hidden',
  },
  confidenceBar: { height: '100%', borderRadius: 4 },
  confidenceValue: { fontSize: FontSize.sm, fontWeight: '600', color: Colors.text, width: 36, textAlign: 'right' },
  reasoning: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
    lineHeight: 18,
    fontStyle: 'italic',
  },
});
