import React from 'react';
import { View, Text, StyleSheet, Platform } from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors, FontSize, Spacing } from '@/constants/theme';

interface GlassHeaderProps {
  title: string;
  subtitle?: string;
  rightElement?: React.ReactNode;
}

export function GlassHeader({ title, subtitle, rightElement }: GlassHeaderProps) {
  const insets = useSafeAreaInsets();

  const content = (
    <View style={[styles.content, { paddingTop: insets.top + Spacing.sm }]}>
      <View style={styles.textContainer}>
        <Text style={styles.title}>{title}</Text>
        {subtitle && <Text style={styles.subtitle}>{subtitle}</Text>}
      </View>
      {rightElement && <View style={styles.rightElement}>{rightElement}</View>}
    </View>
  );

  if (Platform.OS === 'web') {
    return <View style={styles.webContainer}>{content}</View>;
  }

  return (
    <BlurView intensity={80} tint="light" style={styles.container}>
      <View style={styles.tintOverlay}>{content}</View>
    </BlurView>
  );
}

const styles = StyleSheet.create({
  container: {
    borderBottomWidth: 0.5,
    borderBottomColor: Colors.glass.border,
  },
  webContainer: {
    backgroundColor: Colors.glass.background,
    borderBottomWidth: 0.5,
    borderBottomColor: Colors.glass.border,
  },
  tintOverlay: {
    backgroundColor: Colors.glass.tint,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.xl,
    paddingBottom: Spacing.md,
  },
  textContainer: {
    flex: 1,
  },
  title: {
    fontSize: FontSize.title,
    fontWeight: '700',
    color: Colors.primaryDark,
    letterSpacing: -0.5,
  },
  subtitle: {
    fontSize: FontSize.sm,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  rightElement: {
    marginLeft: Spacing.md,
  },
});
