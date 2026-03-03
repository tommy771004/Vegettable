import React from 'react';
import { View, StyleSheet, ViewStyle, Platform } from 'react-native';
import { BlurView } from 'expo-blur';
import { Colors, BorderRadius, Shadow, Spacing } from '@/constants/theme';

interface GlassCardProps {
  children: React.ReactNode;
  style?: ViewStyle;
  intensity?: number;
  tint?: 'light' | 'dark' | 'default';
  noPadding?: boolean;
}

export function GlassCard({
  children,
  style,
  intensity = 60,
  tint = 'light',
  noPadding = false,
}: GlassCardProps) {
  if (Platform.OS === 'web') {
    return (
      <View style={[styles.webFallback, !noPadding && styles.padding, style]}>
        {children}
      </View>
    );
  }

  return (
    <View style={[styles.container, style]}>
      <BlurView intensity={intensity} tint={tint} style={styles.blur}>
        <View style={[styles.inner, !noPadding && styles.padding]}>
          {children}
        </View>
      </BlurView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: BorderRadius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.glass.border,
    ...Shadow.glass,
  },
  blur: {
    flex: 1,
  },
  inner: {
    flex: 1,
    backgroundColor: Colors.glass.tint,
  },
  padding: {
    padding: Spacing.lg,
  },
  webFallback: {
    borderRadius: BorderRadius.xl,
    backgroundColor: Colors.glass.background,
    borderWidth: 1,
    borderColor: Colors.glass.border,
    ...Shadow.glass,
  },
});
