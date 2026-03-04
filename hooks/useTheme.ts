import { useCallback, useMemo } from 'react';
import { useColorScheme } from 'react-native';
import { useSettings } from './useSettings';
import { Colors } from '@/constants/theme';

/** Dark Mode 顏色覆寫 */
const DarkColors = {
  primary: '#66BB6A',
  primaryLight: '#81C784',
  primaryDark: '#388E3C',
  primarySurface: 'rgba(102, 187, 106, 0.12)',

  glass: {
    background: 'rgba(30, 30, 30, 0.85)',
    backgroundDark: 'rgba(20, 20, 20, 0.90)',
    border: 'rgba(255, 255, 255, 0.12)',
    tint: 'rgba(102, 187, 106, 0.08)',
    shadow: 'rgba(0, 0, 0, 0.40)',
  },

  priceLevel: Colors.priceLevel,
  priceLevelBg: {
    'very-cheap': 'rgba(211, 47, 47, 0.18)',
    'cheap': 'rgba(255, 138, 128, 0.18)',
    'normal': 'rgba(130, 177, 255, 0.18)',
    'expensive': 'rgba(21, 101, 192, 0.18)',
  },

  trend: Colors.trend,

  background: '#121212',
  backgroundGradientStart: '#1A1A2E',
  backgroundGradientEnd: '#16213E',
  surface: '#1E1E1E',
  text: '#E1E1E1',
  textSecondary: '#B0B0B0',
  textTertiary: '#808080',
  divider: 'rgba(255, 255, 255, 0.10)',
  white: '#FFFFFF',
  black: '#000000',
} as const;

export function useTheme() {
  const systemScheme = useColorScheme();
  const { settings, updateSettings } = useSettings();

  const isDark = useMemo(() => {
    const mode = settings.darkMode || 'system';
    if (mode === 'system') return systemScheme === 'dark';
    return mode === 'dark';
  }, [settings.darkMode, systemScheme]);

  const colors = useMemo(() => (isDark ? DarkColors : Colors), [isDark]);

  const setDarkMode = useCallback(
    (mode: 'system' | 'light' | 'dark') => {
      updateSettings({ darkMode: mode });
    },
    [updateSettings]
  );

  return { isDark, colors, setDarkMode };
}
