import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { GlassHeader } from '@/components/GlassHeader';
import { CategoryFilter } from '@/components/CategoryFilter';
import { MarketFilter } from '@/components/MarketFilter';
import { ProductListItem } from '@/components/ProductListItem';
import { LoadingView, ErrorView } from '@/components/LoadingView';
import { useProducts } from '@/hooks/useProducts';
import { useFavorites } from '@/hooks/useFavorites';
import { useSettings } from '@/hooks/useSettings';
import { useOfflineCache } from '@/hooks/useOfflineCache';
import { Colors, FontSize, Spacing } from '@/constants/theme';
import { ProductSummary, Market } from '@/types';
import { fetchMarkets } from '@/services/api';

export default function HomeScreen() {
  const router = useRouter();
  const {
    products,
    allProducts,
    loading,
    error,
    selectedCategory,
    setSelectedCategory,
    refresh,
  } = useProducts();
  const { isFavorite, toggleFavorite } = useFavorites();
  const { settings } = useSettings();
  const { saveToCache, loadFromCache } = useOfflineCache();
  const [markets, setMarkets] = useState<Market[]>([]);
  const [selectedMarket, setSelectedMarket] = useState<string | null>(null);
  const [isOffline, setIsOffline] = useState(false);

  // 載入市場清單
  useEffect(() => {
    fetchMarkets().then(setMarkets).catch(() => {});
  }, []);

  // 離線快取: 產品載入成功後存入快取
  useEffect(() => {
    if (allProducts.length > 0) {
      saveToCache(allProducts);
      setIsOffline(false);
    }
  }, [allProducts]);

  // 離線快取: 載入失敗時嘗試讀取快取
  useEffect(() => {
    if (error && allProducts.length === 0) {
      loadFromCache().then(({ products: cached }) => {
        if (cached.length > 0) {
          setIsOffline(true);
        }
      });
    }
  }, [error]);

  const navigateToDetail = (product: ProductSummary) => {
    router.push({
      pathname: '/detail/[cropName]',
      params: { cropName: product.cropName },
    });
  };

  const renderItem = ({ item }: { item: ProductSummary }) => (
    <ProductListItem
      product={item}
      isFavorite={isFavorite(item.cropCode)}
      onToggleFavorite={() => toggleFavorite(item.cropCode)}
      onPress={() => navigateToDetail(item)}
      priceUnit={settings.priceUnit}
      showRetailPrice={settings.showRetailPrice}
    />
  );

  return (
    <LinearGradient
      colors={[Colors.backgroundGradientStart, Colors.backgroundGradientEnd]}
      style={styles.container}
    >
      <GlassHeader
        title="當令蔬果生鮮"
        subtitle="即時批發行情 · 當季便宜一目瞭然"
      />

      {loading && products.length === 0 ? (
        <LoadingView />
      ) : error && products.length === 0 ? (
        <ErrorView message={error} onRetry={refresh} />
      ) : (
        <FlatList
          data={products}
          renderItem={renderItem}
          keyExtractor={(item) => item.cropCode}
          ListHeaderComponent={
            <View style={styles.filterContainer}>
              <CategoryFilter
                selected={selectedCategory}
                onSelect={setSelectedCategory}
              />
              {markets.length > 0 && (
                <MarketFilter
                  markets={markets}
                  selected={selectedMarket}
                  onSelect={setSelectedMarket}
                />
              )}
              {isOffline && (
                <Text style={styles.offlineHint}>
                  離線模式 — 顯示上次快取的資料
                </Text>
              )}
            </View>
          }
          contentContainerStyle={styles.listContent}
          refreshControl={
            <RefreshControl
              refreshing={loading}
              onRefresh={refresh}
              tintColor={Colors.primary}
              colors={[Colors.primary]}
            />
          }
          showsVerticalScrollIndicator={false}
        />
      )}
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  filterContainer: {
    paddingVertical: Spacing.md,
  },
  offlineHint: {
    textAlign: 'center',
    fontSize: FontSize.xs,
    color: Colors.trend.up,
    paddingVertical: Spacing.xs,
  },
  listContent: {
    paddingBottom: 100,
  },
});
