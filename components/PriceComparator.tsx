import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ActivityIndicator, ScrollView, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { GlassCard } from './GlassCard';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { ProductSummary } from '@/types';
import { compareMarketPrices } from '@/services/api';

interface Props {
  products: ProductSummary[];
}

export function PriceComparator({ products }: Props) {
  const [selected, setSelected] = useState<string[]>([]);
  const [comparisons, setComparisons] = useState<Record<string, any[]>>({});
  const [loading, setLoading] = useState(false);

  const toggleProduct = (cropName: string) => {
    setSelected(prev => {
      if (prev.includes(cropName)) return prev.filter(n => n !== cropName);
      if (prev.length >= 2) return [prev[1], cropName];
      return [...prev, cropName];
    });
  };

  useEffect(() => {
    if (selected.length === 2) loadComparison();
  }, [selected]);

  const loadComparison = async () => {
    setLoading(true);
    try {
      const results: Record<string, any[]> = {};
      for (const crop of selected) {
        results[crop] = await compareMarketPrices(crop);
      }
      setComparisons(results);
    } catch {
      // ignore
    }
    setLoading(false);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>選擇兩個品項比較</Text>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.selector}>
        {products.slice(0, 20).map(p => (
          <TouchableOpacity
            key={p.cropCode}
            onPress={() => toggleProduct(p.cropName)}
            style={[styles.chip, selected.includes(p.cropName) && styles.chipSelected]}
          >
            <Text style={[
              styles.chipText,
              selected.includes(p.cropName) && styles.chipTextSelected,
            ]}>
              {p.cropName}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {selected.length === 2 && (
        <GlassCard style={styles.compareCard}>
          {loading ? (
            <ActivityIndicator color={Colors.primary} />
          ) : (
            <View>
              <View style={styles.compareHeader}>
                <Text style={styles.compareTitle}>{selected[0]} vs {selected[1]}</Text>
              </View>

              <View style={styles.compareRow}>
                {selected.map(crop => {
                  const product = products.find(p => p.cropName === crop);
                  if (!product) return null;
                  return (
                    <View key={crop} style={styles.compareItem}>
                      <Text style={styles.compareCrop}>{crop}</Text>
                      <Text style={[styles.comparePrice, { color: Colors.priceLevel[product.priceLevel] }]}>
                        ${product.avgPrice}
                      </Text>
                      <Text style={styles.compareUnit}>/公斤</Text>
                      <View style={styles.compareMeta}>
                        <Ionicons
                          name={product.trend === 'up' ? 'trending-up' : product.trend === 'down' ? 'trending-down' : 'remove'}
                          size={14}
                          color={Colors.trend[product.trend]}
                        />
                        <Text style={styles.compareVolume}>
                          {(product.volume / 1000).toFixed(0)}公噸
                        </Text>
                      </View>
                    </View>
                  );
                })}
              </View>

              {Object.keys(comparisons).length > 0 && (
                <View style={styles.marketSection}>
                  <Text style={styles.marketTitle}>各市場價格</Text>
                  {comparisons[selected[0]]?.slice(0, 5).map(mp => (
                    <View key={mp.marketName} style={styles.marketRow}>
                      <Text style={styles.marketName}>{mp.marketName}</Text>
                      <Text style={styles.marketPrice}>${mp.avgPrice}</Text>
                      <Text style={styles.marketPrice2}>
                        ${comparisons[selected[1]]?.find((x: any) => x.marketName === mp.marketName)?.avgPrice ?? '-'}
                      </Text>
                    </View>
                  ))}
                </View>
              )}
            </View>
          )}
        </GlassCard>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { padding: Spacing.lg },
  title: { fontSize: FontSize.lg, fontWeight: '600', color: Colors.text, marginBottom: Spacing.sm },
  selector: { marginBottom: Spacing.md },
  chip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    borderRadius: BorderRadius.pill,
    backgroundColor: Colors.glass.background,
    borderWidth: 0.5,
    borderColor: Colors.glass.border,
    marginRight: Spacing.xs,
  },
  chipSelected: { borderColor: Colors.primary, backgroundColor: Colors.primarySurface },
  chipText: { fontSize: FontSize.sm, color: Colors.textSecondary },
  chipTextSelected: { color: Colors.primary, fontWeight: '600' },
  compareCard: { marginHorizontal: 0 },
  compareHeader: { marginBottom: Spacing.md },
  compareTitle: { fontSize: FontSize.lg, fontWeight: '700', color: Colors.text },
  compareRow: { flexDirection: 'row', justifyContent: 'space-around' },
  compareItem: { alignItems: 'center', flex: 1 },
  compareCrop: { fontSize: FontSize.md, fontWeight: '600', color: Colors.text },
  comparePrice: { fontSize: FontSize.xxl, fontWeight: '700', marginVertical: 4 },
  compareUnit: { fontSize: FontSize.xs, color: Colors.textTertiary },
  compareMeta: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 4 },
  compareVolume: { fontSize: FontSize.xs, color: Colors.textTertiary },
  marketSection: { marginTop: Spacing.lg, borderTopWidth: 0.5, borderTopColor: Colors.divider, paddingTop: Spacing.md },
  marketTitle: { fontSize: FontSize.md, fontWeight: '600', color: Colors.text, marginBottom: Spacing.sm },
  marketRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 4 },
  marketName: { flex: 1, fontSize: FontSize.sm, color: Colors.textSecondary },
  marketPrice: { width: 70, fontSize: FontSize.sm, color: Colors.text, textAlign: 'right', fontWeight: '600' },
  marketPrice2: { width: 70, fontSize: FontSize.sm, color: Colors.primaryLight, textAlign: 'right', fontWeight: '600' },
});
