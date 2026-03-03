import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { CropCategory } from '@/types';
import { CATEGORIES } from '@/constants/categories';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface CategoryFilterProps {
  selected: CropCategory | 'all';
  onSelect: (category: CropCategory | 'all') => void;
}

export function CategoryFilter({ selected, onSelect }: CategoryFilterProps) {
  const allCategories = [
    { key: 'all' as const, label: '全部', icon: 'apps', color: Colors.primary },
    ...CATEGORIES,
  ];

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.scrollContent}
      style={styles.container}
    >
      {allCategories.map((cat) => {
        const isSelected = selected === cat.key;
        return (
          <TouchableOpacity
            key={cat.key}
            onPress={() => onSelect(cat.key)}
            activeOpacity={0.7}
          >
            {isSelected ? (
              <View style={[styles.chipSelected, { backgroundColor: cat.color + '20' }]}>
                {Platform.OS !== 'web' ? (
                  <BlurView intensity={40} tint="light" style={styles.chipBlur}>
                    <View style={[styles.chipInner, { backgroundColor: cat.color + '10' }]}>
                      <Ionicons name={cat.icon as any} size={16} color={cat.color} />
                      <Text style={[styles.chipText, styles.chipTextSelected, { color: cat.color }]}>
                        {cat.label}
                      </Text>
                    </View>
                  </BlurView>
                ) : (
                  <View style={styles.chipInner}>
                    <Ionicons name={cat.icon as any} size={16} color={cat.color} />
                    <Text style={[styles.chipText, styles.chipTextSelected, { color: cat.color }]}>
                      {cat.label}
                    </Text>
                  </View>
                )}
              </View>
            ) : (
              <View style={styles.chip}>
                <Ionicons name={cat.icon as any} size={16} color={Colors.textTertiary} />
                <Text style={styles.chipText}>{cat.label}</Text>
              </View>
            )}
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    maxHeight: 50,
  },
  scrollContent: {
    paddingHorizontal: Spacing.lg,
    gap: Spacing.sm,
    alignItems: 'center',
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.pill,
    backgroundColor: Colors.glass.background,
    borderWidth: 1,
    borderColor: Colors.glass.border,
  },
  chipSelected: {
    borderRadius: BorderRadius.pill,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.glass.border,
  },
  chipBlur: {
    borderRadius: BorderRadius.pill,
  },
  chipInner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
  },
  chipText: {
    fontSize: FontSize.sm,
    color: Colors.textTertiary,
    fontWeight: '500',
  },
  chipTextSelected: {
    fontWeight: '600',
  },
});
