import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { GlassCard } from './GlassCard';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { Recipe } from '@/types';

interface Props {
  recipes: Recipe[];
}

const DIFFICULTY_CONFIG = {
  easy: { label: '簡單', color: '#2E7D32', icon: 'flash' },
  medium: { label: '中等', color: '#F57C00', icon: 'flame' },
  hard: { label: '進階', color: '#D32F2F', icon: 'bonfire' },
} as const;

export function RecipeCard({ recipes }: Props) {
  if (recipes.length === 0) return null;

  return (
    <GlassCard style={styles.card}>
      <View style={styles.header}>
        <Ionicons name="restaurant-outline" size={18} color={Colors.primary} />
        <Text style={styles.title}>推薦食譜</Text>
      </View>

      {recipes.map((recipe, idx) => {
        const diff = DIFFICULTY_CONFIG[recipe.difficulty];
        return (
          <View key={idx} style={[styles.recipeItem, idx > 0 && styles.recipeItemBorder]}>
            <View style={styles.recipeHeader}>
              <Text style={styles.recipeName}>{recipe.name}</Text>
              <View style={styles.metaRow}>
                <View style={[styles.diffBadge, { backgroundColor: diff.color + '18' }]}>
                  <Ionicons name={diff.icon as any} size={10} color={diff.color} />
                  <Text style={[styles.diffText, { color: diff.color }]}>{diff.label}</Text>
                </View>
                <View style={styles.timeBadge}>
                  <Ionicons name="time-outline" size={10} color={Colors.textTertiary} />
                  <Text style={styles.timeText}>{recipe.cookTimeMinutes}分</Text>
                </View>
              </View>
            </View>
            <Text style={styles.recipeDesc}>{recipe.description}</Text>
            <Text style={styles.ingredients}>
              食材：{recipe.ingredients.join('、')}
            </Text>
          </View>
        );
      })}
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  card: { marginHorizontal: 0, marginTop: Spacing.md },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.md,
  },
  title: { fontSize: FontSize.md, fontWeight: '600', color: Colors.text },
  recipeItem: { paddingVertical: Spacing.sm },
  recipeItemBorder: { borderTopWidth: 0.5, borderTopColor: Colors.divider },
  recipeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  recipeName: { fontSize: FontSize.md, fontWeight: '600', color: Colors.text },
  metaRow: { flexDirection: 'row', gap: Spacing.sm },
  diffBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: BorderRadius.pill,
  },
  diffText: { fontSize: FontSize.xs, fontWeight: '600' },
  timeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  timeText: { fontSize: FontSize.xs, color: Colors.textTertiary },
  recipeDesc: {
    fontSize: FontSize.sm,
    color: Colors.textSecondary,
    marginTop: 4,
  },
  ingredients: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
    marginTop: 4,
  },
});
