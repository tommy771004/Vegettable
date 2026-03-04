import React from 'react';
import { TouchableOpacity, Share, Platform, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing } from '@/constants/theme';

interface Props {
  cropName: string;
  avgPrice: number;
  priceLevel: string;
  size?: number;
}

const LEVEL_TEXT: Record<string, string> = {
  'very-cheap': '非常便宜',
  'cheap': '相對便宜',
  'normal': '正常偏貴',
  'expensive': '偏貴',
};

export function ShareButton({ cropName, avgPrice, priceLevel, size = 22 }: Props) {
  const handleShare = async () => {
    const levelText = LEVEL_TEXT[priceLevel] || '正常';
    const message = `${cropName} 目前批發均價 $${avgPrice}/kg，${levelText}！\n\n— 來自「當令蔬果生鮮」App`;

    try {
      await Share.share(
        Platform.OS === 'ios'
          ? { message }
          : { message, title: `${cropName} 價格分享` }
      );
    } catch {
      // 使用者取消
    }
  };

  return (
    <TouchableOpacity onPress={handleShare} style={styles.button} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
      <Ionicons name="share-outline" size={size} color={Colors.primary} />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: { padding: Spacing.xs },
});
