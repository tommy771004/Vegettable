import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { GlassCard } from './GlassCard';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { SeasonalInfo } from '@/types';

interface Props {
  data: SeasonalInfo[];
}

const MONTHS = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
const currentMonth = new Date().getMonth() + 1;

export function SeasonalCalendar({ data }: Props) {
  return (
    <ScrollView showsVerticalScrollIndicator={false}>
      {data.map(item => (
        <GlassCard key={item.cropName} style={styles.card}>
          <View style={styles.header}>
            <View style={styles.nameRow}>
              <Text style={styles.cropName}>{item.cropName}</Text>
              {item.isInSeason && (
                <View style={styles.inSeasonBadge}>
                  <Ionicons name="checkmark-circle" size={12} color={Colors.primary} />
                  <Text style={styles.inSeasonText}>當季</Text>
                </View>
              )}
            </View>
            <Text style={styles.note}>{item.seasonNote}</Text>
          </View>

          <View style={styles.monthGrid}>
            {MONTHS.map((label, idx) => {
              const month = idx + 1;
              const isPeak = item.peakMonths.includes(month);
              const isCurrent = month === currentMonth;
              return (
                <View key={month} style={[
                  styles.monthCell,
                  isPeak && styles.monthPeak,
                  isCurrent && styles.monthCurrent,
                ]}>
                  <Text style={[
                    styles.monthText,
                    isPeak && styles.monthTextPeak,
                    isCurrent && styles.monthTextCurrent,
                  ]}>
                    {label}
                  </Text>
                </View>
              );
            })}
          </View>
        </GlassCard>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  card: { marginHorizontal: 0, marginBottom: Spacing.sm },
  header: { marginBottom: Spacing.sm },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm },
  cropName: { fontSize: FontSize.lg, fontWeight: '600', color: Colors.text },
  inSeasonBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
    backgroundColor: Colors.primarySurface,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: BorderRadius.pill,
  },
  inSeasonText: { fontSize: FontSize.xs, color: Colors.primary, fontWeight: '600' },
  note: { fontSize: FontSize.sm, color: Colors.textTertiary, marginTop: 2 },
  monthGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 4,
  },
  monthCell: {
    width: '23%',
    paddingVertical: 4,
    alignItems: 'center',
    borderRadius: BorderRadius.sm,
    backgroundColor: 'rgba(0,0,0,0.03)',
  },
  monthPeak: {
    backgroundColor: Colors.primarySurface,
  },
  monthCurrent: {
    borderWidth: 1.5,
    borderColor: Colors.primary,
  },
  monthText: { fontSize: FontSize.xs, color: Colors.textTertiary },
  monthTextPeak: { color: Colors.primary, fontWeight: '600' },
  monthTextCurrent: { color: Colors.primaryDark, fontWeight: '700' },
});
