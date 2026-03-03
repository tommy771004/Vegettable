import React, { useState, useMemo } from 'react';
import {
  View,
  FlatList,
  Text,
  StyleSheet,
} from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { GlassHeader } from '@/components/GlassHeader';
import { SearchBar } from '@/components/SearchBar';
import { ProductListItem } from '@/components/ProductListItem';
import { GlassCard } from '@/components/GlassCard';
import { LoadingView } from '@/components/LoadingView';
import { useProducts } from '@/hooks/useProducts';
import { useFavorites } from '@/hooks/useFavorites';
import { useSettings } from '@/hooks/useSettings';
import { searchProducts } from '@/services/api';
import { Colors, FontSize, Spacing } from '@/constants/theme';
import { ProductSummary } from '@/types';
import { VEGETABLE_SUB_CATEGORIES } from '@/constants/categories';

export default function SearchScreen() {
  const router = useRouter();
  const { allProducts, loading } = useProducts();
  const { isFavorite, toggleFavorite } = useFavorites();
  const { settings } = useSettings();
  const [keyword, setKeyword] = useState('');

  const results = useMemo(() => {
    if (!keyword.trim()) return [];
    return searchProducts(allProducts, keyword);
  }, [allProducts, keyword]);

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
      <GlassHeader title="搜尋" subtitle="輸入品名或別名查詢" />

      <View style={styles.searchContainer}>
        <SearchBar value={keyword} onChangeText={setKeyword} />
      </View>

      {loading ? (
        <LoadingView message="載入資料中..." />
      ) : keyword.trim() === '' ? (
        <View style={styles.hintContainer}>
          <GlassCard style={styles.hintCard}>
            <Text style={styles.hintTitle}>搜尋小技巧</Text>
            <Text style={styles.hintText}>
              支援別名搜尋！例如輸入「地瓜」可找到「甘薯」，
              輸入「高麗菜」可找到「甘藍」。
            </Text>
            <View style={styles.subCategories}>
              <Text style={styles.subCatTitle}>蔬菜分類：</Text>
              {VEGETABLE_SUB_CATEGORIES.map((cat) => (
                <Text key={cat.key} style={styles.subCatItem}>
                  {cat.label}
                </Text>
              ))}
            </View>
          </GlassCard>
        </View>
      ) : results.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>找不到「{keyword}」相關品項</Text>
          <Text style={styles.emptySubText}>試試其他名稱或別名</Text>
        </View>
      ) : (
        <FlatList
          data={results}
          renderItem={renderItem}
          keyExtractor={(item) => item.cropCode}
          contentContainerStyle={styles.listContent}
          ListHeaderComponent={
            <Text style={styles.resultCount}>
              共找到 {results.length} 項結果
            </Text>
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
  searchContainer: {
    paddingVertical: Spacing.md,
  },
  hintContainer: {
    padding: Spacing.lg,
  },
  hintCard: {
    marginHorizontal: 0,
  },
  hintTitle: {
    fontSize: FontSize.lg,
    fontWeight: '600',
    color: Colors.primary,
    marginBottom: Spacing.sm,
  },
  hintText: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    lineHeight: 22,
  },
  subCategories: {
    marginTop: Spacing.md,
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
    alignItems: 'center',
  },
  subCatTitle: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    color: Colors.text,
  },
  subCatItem: {
    fontSize: FontSize.sm,
    color: Colors.primaryLight,
    backgroundColor: Colors.primarySurface,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: 8,
    overflow: 'hidden',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing.xxxl,
  },
  emptyText: {
    fontSize: FontSize.lg,
    color: Colors.textSecondary,
    fontWeight: '600',
  },
  emptySubText: {
    fontSize: FontSize.md,
    color: Colors.textTertiary,
    marginTop: Spacing.xs,
  },
  resultCount: {
    fontSize: FontSize.sm,
    color: Colors.textTertiary,
    paddingHorizontal: Spacing.xl,
    paddingVertical: Spacing.sm,
  },
  listContent: {
    paddingBottom: 100,
  },
});
