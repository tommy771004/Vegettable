import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated, Easing } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, FontSize, Spacing } from '@/constants/theme';

interface LoadingViewProps {
  message?: string;
}

export function LoadingView({ message = '正在載入當令蔬果行情...' }: LoadingViewProps) {
  const rotation = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const animation = Animated.loop(
      Animated.timing(rotation, {
        toValue: 1,
        duration: 2000,
        easing: Easing.linear,
        useNativeDriver: true,
      })
    );
    animation.start();
    return () => animation.stop();
  }, [rotation]);

  const rotate = rotation.interpolate({
    inputRange: [0, 1],
    outputRange: ['0deg', '360deg'],
  });

  return (
    <View style={styles.container}>
      <Animated.View style={{ transform: [{ rotate }] }}>
        <Ionicons name="leaf" size={48} color={Colors.primary} />
      </Animated.View>
      <Text style={styles.message}>{message}</Text>
    </View>
  );
}

export function ErrorView({
  message,
  onRetry,
}: {
  message: string;
  onRetry: () => void;
}) {
  return (
    <View style={styles.container}>
      <Ionicons name="cloud-offline-outline" size={48} color={Colors.textTertiary} />
      <Text style={styles.errorMessage}>{message}</Text>
      <Text style={styles.retryText} onPress={onRetry}>
        點擊重試
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing.xxxl,
    gap: Spacing.lg,
  },
  message: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  errorMessage: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  retryText: {
    fontSize: FontSize.md,
    color: Colors.primary,
    fontWeight: '600',
  },
});
