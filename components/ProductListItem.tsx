import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { ProductSummary, PriceUnit } from '@/types';
import { GlassCard } from './GlassCard';
import { PriceIndicator } from './PriceIndicator';
import { TrendArrow } from './TrendArrow';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { convertPrice, estimateRetailPrice, formatPrice, getPriceUnitLabel } from '@/utils/price';

interface ProductListItemProps {
  product: ProductSummary;
  isFavorite: boolean;
  onToggleFavorite: () => void;
  onPress: () => void;
  priceUnit: PriceUnit;
  showRetailPrice: boolean;
}

export function ProductListItem({
  product,
  isFavorite,
  onToggleFavorite,
  onPress,
  priceUnit,
  showRetailPrice,
}: ProductListItemProps) {
  const displayPrice = showRetailPrice
    ? estimateRetailPrice(convertPrice(product.avgPrice, priceUnit))
    : convertPrice(product.avgPrice, priceUnit);

  const openGoogleImages = () => {
    const query = encodeURIComponent(product.cropName);
    Linking.openURL(`https://www.google.com/search?tbm=isch&q=${query}`);
  };

  return (
    <TouchableOpacity onPress={onPress} activeOpacity={0.7}>
      <GlassCard style={styles.card}>
        <View style={styles.row}>
          {/* 左側：價格等級指示 + 品名 */}
          <View style={styles.leftSection}>
            <PriceIndicator level={product.priceLevel} compact />
            <View style={styles.nameContainer}>
              <View style={styles.nameRow}>
                <Text style={styles.cropName}>{product.cropName}</Text>
                <TrendArrow trend={product.trend} />
              </View>
              {product.aliases.length > 0 && (
                <Text style={styles.aliases} numberOfLines={1}>
                  {product.aliases.slice(0, 3).join('、')}
                </Text>
              )}
            </View>
          </View>

          {/* 右側：價格 + 操作 */}
          <View style={styles.rightSection}>
            <View style={styles.priceContainer}>
              <Text style={[styles.price, { color: Colors.priceLevel[product.priceLevel] }]}>
                ${formatPrice(displayPrice)}
              </Text>
              <Text style={styles.priceUnit}>
                {showRetailPrice ? '零售估' : '批發'} {getPriceUnitLabel(priceUnit)}
              </Text>
            </View>
            <View style={styles.actions}>
              <TouchableOpacity onPress={onToggleFavorite} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                <Ionicons
                  name={isFavorite ? 'heart' : 'heart-outline'}
                  size={20}
                  color={isFavorite ? Colors.priceLevel['very-cheap'] : Colors.textTertiary}
                />
              </TouchableOpacity>
              <TouchableOpacity onPress={openGoogleImages} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                <Ionicons name="image-outline" size={18} color={Colors.textTertiary} />
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* 價格等級標籤 */}
        <View style={styles.footer}>
          <PriceIndicator level={product.priceLevel} />
          <Text style={styles.volumeText}>
            交易量 {(product.volume / 1000).toFixed(0)} 公噸
          </Text>
        </View>
      </GlassCard>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    marginHorizontal: Spacing.lg,
    marginVertical: Spacing.xs,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  leftSection: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    gap: Spacing.sm,
  },
  nameContainer: {
    flex: 1,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  cropName: {
    fontSize: FontSize.lg,
    fontWeight: '600',
    color: Colors.text,
  },
  aliases: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
    marginTop: 2,
  },
  rightSection: {
    alignItems: 'flex-end',
    gap: Spacing.xs,
  },
  priceContainer: {
    alignItems: 'flex-end',
  },
  price: {
    fontSize: FontSize.xl,
    fontWeight: '700',
  },
  priceUnit: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
  },
  actions: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: Spacing.sm,
    paddingTop: Spacing.sm,
    borderTopWidth: 0.5,
    borderTopColor: Colors.divider,
  },
  volumeText: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
  },
});
