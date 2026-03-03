import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Linking,
  ActivityIndicator,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { GlassCard } from '@/components/GlassCard';
import { PriceIndicator } from '@/components/PriceIndicator';
import { TrendArrow } from '@/components/TrendArrow';
import { DailyChart, MonthlyChart } from '@/components/PriceChart';
import { LoadingView } from '@/components/LoadingView';
import { useProducts } from '@/hooks/useProducts';
import { useFavorites } from '@/hooks/useFavorites';
import { useSettings } from '@/hooks/useSettings';
import { fetchProductDetail } from '@/services/api';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { convertPrice, estimateRetailPrice, formatPrice, getPriceUnitLabel } from '@/utils/price';
import { DailyPrice, MonthlyPrice } from '@/types';

export default function ProductDetailScreen() {
  const { cropName } = useLocalSearchParams<{ cropName: string }>();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { allProducts } = useProducts();
  const { isFavorite, toggleFavorite } = useFavorites();
  const { settings } = useSettings();

  const [dailyPrices, setDailyPrices] = useState<DailyPrice[]>([]);
  const [monthlyPrices, setMonthlyPrices] = useState<MonthlyPrice[]>([]);
  const [loadingDetail, setLoadingDetail] = useState(true);

  const product = allProducts.find((p) => p.cropName === cropName);

  useEffect(() => {
    if (cropName) {
      loadDetail();
    }
  }, [cropName]);

  const loadDetail = async () => {
    try {
      setLoadingDetail(true);
      const detail = await fetchProductDetail(cropName || '');
      setDailyPrices(detail.dailyPrices);
      setMonthlyPrices(detail.monthlyPrices);
    } catch {
      // 使用產品摘要中的近期價格
      if (product) {
        setDailyPrices(product.recentPrices);
      }
    } finally {
      setLoadingDetail(false);
    }
  };

  const openGoogleImages = () => {
    const query = encodeURIComponent(cropName || '');
    Linking.openURL(`https://www.google.com/search?tbm=isch&q=${query}`);
  };

  if (!product) {
    return (
      <LinearGradient
        colors={[Colors.backgroundGradientStart, Colors.backgroundGradientEnd]}
        style={styles.container}
      >
        <LoadingView message={`正在查詢 ${cropName} 的資料...`} />
      </LinearGradient>
    );
  }

  const displayPrice = settings.showRetailPrice
    ? estimateRetailPrice(convertPrice(product.avgPrice, settings.priceUnit))
    : convertPrice(product.avgPrice, settings.priceUnit);

  const historicalDisplay = settings.showRetailPrice
    ? estimateRetailPrice(convertPrice(product.historicalAvgPrice, settings.priceUnit))
    : convertPrice(product.historicalAvgPrice, settings.priceUnit);

  return (
    <LinearGradient
      colors={[Colors.backgroundGradientStart, Colors.backgroundGradientEnd]}
      style={styles.container}
    >
      <ScrollView
        contentContainerStyle={[
          styles.scrollContent,
          { paddingTop: insets.top + Spacing.sm },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* 導航列 */}
        <View style={styles.nav}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
            <Ionicons name="chevron-back" size={24} color={Colors.primary} />
            <Text style={styles.backText}>返回</Text>
          </TouchableOpacity>
          <View style={styles.navActions}>
            <TouchableOpacity
              onPress={() => toggleFavorite(product.cropCode)}
              style={styles.navButton}
            >
              <Ionicons
                name={isFavorite(product.cropCode) ? 'heart' : 'heart-outline'}
                size={22}
                color={
                  isFavorite(product.cropCode) ? Colors.priceLevel['very-cheap'] : Colors.textTertiary
                }
              />
            </TouchableOpacity>
            <TouchableOpacity onPress={openGoogleImages} style={styles.navButton}>
              <Ionicons name="image-outline" size={22} color={Colors.textTertiary} />
            </TouchableOpacity>
          </View>
        </View>

        {/* 品名 + 價格摘要 */}
        <GlassCard style={styles.headerCard}>
          <View style={styles.headerRow}>
            <View style={styles.headerLeft}>
              <Text style={styles.cropName}>{product.cropName}</Text>
              {product.aliases.length > 0 && (
                <Text style={styles.aliases}>
                  又稱：{product.aliases.join('、')}
                </Text>
              )}
              <PriceIndicator level={product.priceLevel} />
            </View>
            <View style={styles.headerRight}>
              <Text style={[styles.mainPrice, { color: Colors.priceLevel[product.priceLevel] }]}>
                ${formatPrice(displayPrice)}
              </Text>
              <View style={styles.trendRow}>
                <TrendArrow trend={product.trend} showLabel />
                <Text style={styles.priceLabel}>
                  {settings.showRetailPrice ? '零售估價' : '批發均價'}
                </Text>
              </View>
              <Text style={styles.unitLabel}>{getPriceUnitLabel(settings.priceUnit)}</Text>
            </View>
          </View>

          <View style={styles.statsRow}>
            <View style={styles.statItem}>
              <Text style={styles.statValue}>${formatPrice(historicalDisplay)}</Text>
              <Text style={styles.statLabel}>歷史均價</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statItem}>
              <Text style={styles.statValue}>
                {(product.volume / 1000).toFixed(0)} 公噸
              </Text>
              <Text style={styles.statLabel}>近期交易量</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statItem}>
              <Text
                style={[
                  styles.statValue,
                  {
                    color:
                      product.avgPrice < product.historicalAvgPrice
                        ? Colors.trend.down
                        : Colors.trend.up,
                  },
                ]}
              >
                {product.avgPrice < product.historicalAvgPrice ? '↓' : '↑'}
                {Math.abs(
                  ((product.avgPrice - product.historicalAvgPrice) /
                    product.historicalAvgPrice) *
                    100
                ).toFixed(0)}
                %
              </Text>
              <Text style={styles.statLabel}>較歷史均價</Text>
            </View>
          </View>
        </GlassCard>

        {/* 近七日價格走勢 */}
        <GlassCard style={styles.chartCard}>
          {loadingDetail ? (
            <View style={styles.chartLoading}>
              <ActivityIndicator color={Colors.primary} />
              <Text style={styles.chartLoadingText}>載入價格走勢...</Text>
            </View>
          ) : (
            <DailyChart
              data={dailyPrices.length > 0 ? dailyPrices : product.recentPrices}
              title="近七日均價走勢 (元/公斤)"
            />
          )}
        </GlassCard>

        {/* 近三年月均價 */}
        {monthlyPrices.length > 0 && (
          <GlassCard style={styles.chartCard}>
            <MonthlyChart data={monthlyPrices} title="近三年月均價趨勢 (元/公斤)" />
          </GlassCard>
        )}

        {/* 使用提示 */}
        <GlassCard style={styles.tipCard}>
          <View style={styles.tipRow}>
            <Ionicons name="information-circle-outline" size={18} color={Colors.primary} />
            <Text style={styles.tipText}>
              價格為全台批發市場加權平均，零售估價以批發價 × 2.5 計算，僅供參考。
            </Text>
          </View>
        </GlassCard>
      </ScrollView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: 40,
  },
  nav: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  backButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  backText: {
    fontSize: FontSize.md,
    color: Colors.primary,
    fontWeight: '500',
  },
  navActions: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
  navButton: {
    padding: Spacing.xs,
  },
  headerCard: {
    marginHorizontal: 0,
    marginTop: Spacing.sm,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  headerLeft: {
    flex: 1,
    gap: Spacing.sm,
  },
  headerRight: {
    alignItems: 'flex-end',
  },
  cropName: {
    fontSize: FontSize.hero,
    fontWeight: '700',
    color: Colors.text,
    letterSpacing: -0.5,
  },
  aliases: {
    fontSize: FontSize.sm,
    color: Colors.textTertiary,
  },
  mainPrice: {
    fontSize: 36,
    fontWeight: '800',
  },
  trendRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  priceLabel: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
  },
  unitLabel: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
  },
  statsRow: {
    flexDirection: 'row',
    marginTop: Spacing.lg,
    paddingTop: Spacing.md,
    borderTopWidth: 0.5,
    borderTopColor: Colors.divider,
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
    gap: 2,
  },
  statValue: {
    fontSize: FontSize.lg,
    fontWeight: '700',
    color: Colors.text,
  },
  statLabel: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
  },
  statDivider: {
    width: 0.5,
    backgroundColor: Colors.divider,
    marginHorizontal: Spacing.sm,
  },
  chartCard: {
    marginHorizontal: 0,
    marginTop: Spacing.md,
  },
  chartLoading: {
    height: 160,
    justifyContent: 'center',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  chartLoadingText: {
    fontSize: FontSize.sm,
    color: Colors.textTertiary,
  },
  tipCard: {
    marginHorizontal: 0,
    marginTop: Spacing.md,
  },
  tipRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: Spacing.sm,
  },
  tipText: {
    flex: 1,
    fontSize: FontSize.sm,
    color: Colors.textSecondary,
    lineHeight: 20,
  },
});
