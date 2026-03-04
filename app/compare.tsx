import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { PriceComparator } from '@/components/PriceComparator';
import { LoadingView } from '@/components/LoadingView';
import { useProducts } from '@/hooks/useProducts';
import { Colors, Spacing } from '@/constants/theme';

export default function CompareScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { allProducts, loading } = useProducts();

  return (
    <LinearGradient colors={[Colors.backgroundGradientStart, Colors.backgroundGradientEnd]} style={styles.container}>
      <View style={[styles.nav, { paddingTop: insets.top + 8 }]}>
        <TouchableOpacity onPress={() => router.back()} style={styles.navBtn}>
          <Ionicons name="chevron-back" size={24} color={Colors.primaryDark} />
        </TouchableOpacity>
        <Text style={styles.navTitle}>價格比較器</Text>
        <View style={styles.navBtn} />
      </View>

      {loading ? (
        <LoadingView message="載入產品資料..." />
      ) : (
        <PriceComparator products={allProducts} />
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
});
