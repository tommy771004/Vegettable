import React from 'react';
import {
  View,
  FlatList,
  StyleSheet,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { GlassHeader } from '@/components/GlassHeader';
import { CategoryFilter } from '@/components/CategoryFilter';
import { ProductListItem } from '@/components/ProductListItem';
import { LoadingView, ErrorView } from '@/components/LoadingView';
import { useProducts } from '@/hooks/useProducts';
import { useFavorites } from '@/hooks/useFavorites';
import { useSettings } from '@/hooks/useSettings';
import { Colors, Spacing } from '@/constants/theme';
import { ProductSummary } from '@/types';

export default function HomeScreen() {
  const router = useRouter();
  const {
    products,
    loading,
    error,
    selectedCategory,
    setSelectedCategory,
    refresh,
  } = useProducts();
  const { isFavorite, toggleFavorite } = useFavorites();
  const { settings } = useSettings();

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
      ) : error ? (
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
  listContent: {
    paddingBottom: 100,
  },
});
