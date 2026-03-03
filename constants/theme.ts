/** iOS 26 Liquid Glass 風格 — 綠色主題 */
export const Colors = {
  // 主色調 — 自然綠
  primary: '#2E7D32',
  primaryLight: '#4CAF50',
  primaryDark: '#1B5E20',
  primarySurface: 'rgba(46, 125, 50, 0.08)',

  // 玻璃效果
  glass: {
    background: 'rgba(255, 255, 255, 0.72)',
    backgroundDark: 'rgba(255, 255, 255, 0.55)',
    border: 'rgba(255, 255, 255, 0.45)',
    tint: 'rgba(46, 125, 50, 0.06)',
    shadow: 'rgba(0, 0, 0, 0.08)',
  },

  // 價格等級顏色
  priceLevel: {
    'very-cheap': '#D32F2F',      // 紅 — 當令便宜
    'cheap': '#FF8A80',           // 淺紅 — 相對便宜
    'normal': '#82B1FF', // 淺藍 — 略偏貴
    'expensive': '#1565C0',        // 藍 — 偏貴
  },

  priceLevelBg: {
    'very-cheap': 'rgba(211, 47, 47, 0.10)',
    'cheap': 'rgba(255, 138, 128, 0.10)',
    'normal': 'rgba(130, 177, 255, 0.10)',
    'expensive': 'rgba(21, 101, 192, 0.10)',
  },

  // 趨勢箭頭
  trend: {
    up: '#D32F2F',
    down: '#2E7D32',
    stable: '#757575',
  },

  // 通用
  background: '#E8F5E9',
  backgroundGradientStart: '#E8F5E9',
  backgroundGradientEnd: '#C8E6C9',
  surface: '#FFFFFF',
  text: '#1B1B1F',
  textSecondary: '#49454F',
  textTertiary: '#79747E',
  divider: 'rgba(0, 0, 0, 0.06)',
  white: '#FFFFFF',
  black: '#000000',
} as const;

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32,
} as const;

export const BorderRadius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  pill: 999,
} as const;

export const FontSize = {
  xs: 11,
  sm: 13,
  md: 15,
  lg: 17,
  xl: 20,
  xxl: 24,
  title: 28,
  hero: 34,
} as const;

export const Shadow = {
  glass: {
    shadowColor: Colors.glass.shadow,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1,
    shadowRadius: 12,
    elevation: 4,
  },
  card: {
    shadowColor: 'rgba(0,0,0,0.12)',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1,
    shadowRadius: 16,
    elevation: 6,
  },
} as const;
