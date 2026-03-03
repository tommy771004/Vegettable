import React, { useMemo } from 'react';
import {
  View,
  FlatList,
  Text,
  StyleSheet,
} from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { GlassHeader } from '@/components/GlassHeader';
import { ProductListItem } from '@/components/ProductListItem';
import { GlassCard } from '@/components/GlassCard';
import { useProducts } from '@/hooks/useProducts';
import { useFavorites } from '@/hooks/useFavorites';
import { useSettings } from '@/hooks/useSettings';
import { Colors, FontSize, Spacing } from '@/constants/theme';
import { ProductSummary } from '@/types';

export default function FavoritesScreen() {
  const router = useRouter();
  const { allProducts } = useProducts();
  const { favorites, isFavorite, toggleFavorite } = useFavorites();
  const { settings } = useSettings();

  const favoriteProducts = useMemo(() => {
    return allProducts.filter((p) => favorites.includes(p.cropCode));
  }, [allProducts, favorites]);

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
        title="常買清單"
        subtitle={favoriteProducts.length > 0 ? `${favoriteProducts.length} 個品項` : undefined}
      />

      {favoriteProducts.length === 0 ? (
        <View style={styles.emptyContainer}>
          <GlassCard style={styles.emptyCard}>
            <Ionicons
              name="heart-outline"
              size={48}
              color={Colors.textTertiary}
              style={styles.emptyIcon}
            />
            <Text style={styles.emptyTitle}>還沒有常買品項</Text>
            <Text style={styles.emptyText}>
              在行情列表中點擊愛心圖示，將常買的蔬果加入清單，
              下次查價更方便！
            </Text>
          </GlassCard>
        </View>
      ) : (
        <FlatList
          data={favoriteProducts}
          renderItem={renderItem}
          keyExtractor={(item) => item.cropCode}
          contentContainerStyle={styles.listContent}
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
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    padding: Spacing.xl,
  },
  emptyCard: {
    alignItems: 'center',
  },
  emptyIcon: {
    marginBottom: Spacing.md,
  },
  emptyTitle: {
    fontSize: FontSize.lg,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: Spacing.sm,
  },
  emptyText: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
  },
  listContent: {
    paddingTop: Spacing.md,
    paddingBottom: 100,
  },
});
