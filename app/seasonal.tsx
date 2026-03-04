import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { GlassHeader } from '@/components/GlassHeader';
import { SeasonalCalendar } from '@/components/SeasonalCalendar';
import { LoadingView } from '@/components/LoadingView';
import { CategoryFilter } from '@/components/CategoryFilter';
import { Colors, Spacing } from '@/constants/theme';
import { SeasonalInfo } from '@/types';
import { fetchSeasonalInfo } from '@/services/api';

export default function SeasonalScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const [data, setData] = useState<SeasonalInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [category, setCategory] = useState('all');

  useEffect(() => { loadData(); }, [category]);

  const loadData = async () => {
    setLoading(true);
    try {
      const result = await fetchSeasonalInfo(category === 'all' ? undefined : category);
      setData(result);
    } catch {
      setData([]);
    }
    setLoading(false);
  };

  return (
    <LinearGradient colors={[Colors.backgroundGradientStart, Colors.backgroundGradientEnd]} style={styles.container}>
      <View style={[styles.nav, { paddingTop: insets.top + 8 }]}>
        <TouchableOpacity onPress={() => router.back()} style={styles.navBtn}>
          <Ionicons name="chevron-back" size={24} color={Colors.primaryDark} />
        </TouchableOpacity>
        <Text style={styles.navTitle}>當季蔬果日曆</Text>
        <View style={styles.navBtn} />
      </View>

      <CategoryFilter selected={category} onSelect={setCategory} />

      {loading ? (
        <LoadingView message="載入季節資訊..." />
      ) : (
        <View style={styles.content}>
          <SeasonalCalendar data={data} />
        </View>
      )}
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  nav: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.sm,
  },
  navBtn: { width: 40 },
  navTitle: { fontSize: 18, fontWeight: '700', color: Colors.primaryDark },
  content: { flex: 1, paddingHorizontal: Spacing.lg },
});
