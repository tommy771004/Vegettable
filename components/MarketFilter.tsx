import React from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet } from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { Market } from '@/types';

interface Props {
  markets: Market[];
  selected: string | null;
  onSelect: (marketName: string | null) => void;
}

const REGION_ICONS: Record<string, string> = {
  '北部': 'business',
  '中部': 'leaf',
  '南部': 'sunny',
  '東部': 'water',
};

export function MarketFilter({ markets, selected, onSelect }: Props) {
  const grouped = markets.reduce<Record<string, Market[]>>((acc, m) => {
    (acc[m.region] = acc[m.region] || []).push(m);
    return acc;
  }, {});

  return (
    <View style={styles.container}>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.scroll}>
        {/* 全台平均 */}
        <TouchableOpacity onPress={() => onSelect(null)}>
          <BlurView intensity={selected === null ? 50 : 30} tint="light" style={[
            styles.chip,
            selected === null && styles.chipActive,
          ]}>
            <Ionicons name="globe-outline" size={14} color={selected === null ? Colors.primary : Colors.textTertiary} />
            <Text style={[styles.chipText, selected === null && styles.chipTextActive]}>
              全台平均
            </Text>
          </BlurView>
        </TouchableOpacity>

        {Object.entries(grouped).map(([region, regionMarkets]) => (
          <React.Fragment key={region}>
            <View style={styles.regionDivider}>
              <Ionicons
                name={(REGION_ICONS[region] || 'location') as any}
                size={10}
                color={Colors.textTertiary}
              />
            </View>
            {regionMarkets.map(m => (
              <TouchableOpacity key={m.marketCode} onPress={() => onSelect(m.marketName)}>
                <BlurView intensity={selected === m.marketName ? 50 : 30} tint="light" style={[
                  styles.chip,
                  selected === m.marketName && styles.chipActive,
                ]}>
                  <Text style={[
                    styles.chipText,
                    selected === m.marketName && styles.chipTextActive,
                  ]}>
                    {m.marketName}
                  </Text>
                </BlurView>
              </TouchableOpacity>
            ))}
          </React.Fragment>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { marginVertical: Spacing.xs },
  scroll: {
    paddingHorizontal: Spacing.lg,
    gap: Spacing.xs,
    alignItems: 'center',
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    borderRadius: BorderRadius.pill,
    borderWidth: 0.5,
    borderColor: Colors.glass.border,
    overflow: 'hidden',
  },
  chipActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primarySurface,
  },
  chipText: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
  },
  chipTextActive: {
    color: Colors.primary,
    fontWeight: '600',
  },
  regionDivider: {
    paddingHorizontal: 2,
    opacity: 0.5,
  },
});
