import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, TouchableOpacity,
  FlatList, Linking, Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { GlassCard } from '@/components/GlassCard';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

// 主要批發市場 GPS 座標
const MARKETS = [
  { name: '台北一 (萬華)', region: '北部', lat: 25.0303, lng: 121.5066, address: '台北市萬華區萬大路533號' },
  { name: '台北二 (濱江)', region: '北部', lat: 25.0644, lng: 121.5395, address: '台北市中山區民族東路336號' },
  { name: '三重市場', region: '北部', lat: 25.0752, lng: 121.4881, address: '新北市三重區大同北路90號' },
  { name: '桃農綜合', region: '北部', lat: 24.9530, lng: 121.2356, address: '桃園市桃園區萬壽路三段656號' },
  { name: '台中市場', region: '中部', lat: 24.1368, lng: 120.6476, address: '台中市南區忠明南路787號' },
  { name: '溪湖果菜', region: '中部', lat: 23.9601, lng: 120.4789, address: '彰化縣溪湖鎮彰水路四段330號' },
  { name: '西螺果菜', region: '中部', lat: 23.7977, lng: 120.4655, address: '雲林縣西螺鎮中山路287號' },
  { name: '嘉義市場', region: '南部', lat: 23.4738, lng: 120.4364, address: '嘉義市西區北港路900號' },
  { name: '台南市場', region: '南部', lat: 23.0042, lng: 120.2027, address: '台南市安南區怡安路二段102號' },
  { name: '高雄市場', region: '南部', lat: 22.6404, lng: 120.3076, address: '高雄市鳳山區鳳北路15號' },
  { name: '屏東市場', region: '南部', lat: 22.6594, lng: 120.5008, address: '屏東縣屏東市工業路19號' },
  { name: '宜蘭市場', region: '東部', lat: 24.7389, lng: 121.7571, address: '宜蘭縣宜蘭市延平路75號' },
  { name: '花蓮市場', region: '東部', lat: 23.9778, lng: 121.5973, address: '花蓮縣花蓮市中山路一段530號' },
];

export default function MapScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const [selectedRegion, setSelectedRegion] = useState<string | null>(null);

  const filteredMarkets = selectedRegion
    ? MARKETS.filter(m => m.region === selectedRegion)
    : MARKETS;

  const openInMaps = (market: typeof MARKETS[0]) => {
    const url = Platform.select({
      ios: `maps:?q=${encodeURIComponent(market.name)}&ll=${market.lat},${market.lng}`,
      android: `geo:${market.lat},${market.lng}?q=${encodeURIComponent(market.address)}`,
      default: `https://www.google.com/maps/search/?api=1&query=${market.lat},${market.lng}`,
    });
    if (url) Linking.openURL(url);
  };

  const regions = ['北部', '中部', '南部', '東部'];

  return (
    <LinearGradient colors={[Colors.backgroundGradientStart, Colors.backgroundGradientEnd]} style={styles.container}>
      <View style={[styles.nav, { paddingTop: insets.top + 8 }]}>
        <TouchableOpacity onPress={() => router.back()} style={styles.navBtn}>
          <Ionicons name="chevron-back" size={24} color={Colors.primaryDark} />
        </TouchableOpacity>
        <Text style={styles.navTitle}>附近市場</Text>
        <View style={styles.navBtn} />
      </View>

      <View style={styles.regionFilter}>
        <TouchableOpacity
          onPress={() => setSelectedRegion(null)}
          style={[styles.regionChip, !selectedRegion && styles.regionChipActive]}
        >
          <Text style={[styles.regionText, !selectedRegion && styles.regionTextActive]}>全部</Text>
        </TouchableOpacity>
        {regions.map(r => (
          <TouchableOpacity
            key={r}
            onPress={() => setSelectedRegion(r)}
            style={[styles.regionChip, selectedRegion === r && styles.regionChipActive]}
          >
            <Text style={[styles.regionText, selectedRegion === r && styles.regionTextActive]}>{r}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <FlatList
        data={filteredMarkets}
        keyExtractor={m => m.name}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <GlassCard style={styles.marketCard}>
            <TouchableOpacity onPress={() => openInMaps(item)} style={styles.marketRow}>
              <View style={styles.marketIcon}>
                <Ionicons name="storefront" size={24} color={Colors.primary} />
              </View>
              <View style={styles.marketInfo}>
                <Text style={styles.marketName}>{item.name}</Text>
                <Text style={styles.marketAddress}>{item.address}</Text>
                <Text style={styles.marketRegion}>{item.region}</Text>
              </View>
              <Ionicons name="navigate-outline" size={20} color={Colors.primary} />
            </TouchableOpacity>
          </GlassCard>
        )}
      />
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
  regionFilter: {
    flexDirection: 'row',
    paddingHorizontal: Spacing.lg,
    gap: Spacing.sm,
    marginBottom: Spacing.md,
  },
  regionChip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    borderRadius: BorderRadius.pill,
    backgroundColor: Colors.glass.background,
    borderWidth: 0.5,
    borderColor: Colors.glass.border,
  },
  regionChipActive: { borderColor: Colors.primary, backgroundColor: Colors.primarySurface },
  regionText: { fontSize: FontSize.sm, color: Colors.textTertiary },
  regionTextActive: { color: Colors.primary, fontWeight: '600' },
  list: { paddingHorizontal: Spacing.lg, paddingBottom: 100 },
  marketCard: { marginHorizontal: 0, marginBottom: Spacing.sm },
  marketRow: { flexDirection: 'row', alignItems: 'center', gap: Spacing.md },
  marketIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.primarySurface,
    alignItems: 'center',
    justifyContent: 'center',
  },
  marketInfo: { flex: 1 },
  marketName: { fontSize: FontSize.md, fontWeight: '600', color: Colors.text },
  marketAddress: { fontSize: FontSize.sm, color: Colors.textSecondary, marginTop: 2 },
  marketRegion: { fontSize: FontSize.xs, color: Colors.textTertiary, marginTop: 2 },
});
