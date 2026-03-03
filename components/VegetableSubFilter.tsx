import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { VegetableSubCategory } from '@/types';
import { VEGETABLE_SUB_CATEGORIES } from '@/constants/categories';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

interface VegetableSubFilterProps {
  selected: VegetableSubCategory | 'all';
  onSelect: (subCategory: VegetableSubCategory | 'all') => void;
  visible: boolean;
}

export function VegetableSubFilter({ selected, onSelect, visible }: VegetableSubFilterProps) {
  if (!visible) return null;

  const allOptions = [
    { key: 'all' as const, label: '全部蔬菜', icon: 'leaf' },
    ...VEGETABLE_SUB_CATEGORIES,
  ];

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.scrollContent}
      style={styles.container}
    >
      {allOptions.map((item) => {
        const isSelected = selected === item.key;
        return (
          <TouchableOpacity
            key={item.key}
            onPress={() => onSelect(item.key)}
            activeOpacity={0.7}
            style={[
              styles.chip,
              isSelected && styles.chipSelected,
            ]}
          >
            <Ionicons
              name={item.icon as any}
              size={14}
              color={isSelected ? Colors.white : Colors.primary}
            />
            <Text style={[styles.chipText, isSelected && styles.chipTextSelected]}>
              {item.label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    maxHeight: 40,
  },
  scrollContent: {
    paddingHorizontal: Spacing.lg,
    gap: Spacing.xs,
    alignItems: 'center',
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.xs,
    borderRadius: BorderRadius.pill,
    backgroundColor: Colors.primarySurface,
    borderWidth: 1,
    borderColor: Colors.primary + '20',
  },
  chipSelected: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  chipText: {
    fontSize: FontSize.xs,
    color: Colors.primary,
    fontWeight: '500',
  },
  chipTextSelected: {
    color: Colors.white,
  },
});
