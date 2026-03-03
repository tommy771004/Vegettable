import { Platform } from 'react-native';

/**
 * .NET 後端 API 基礎設定
 *
 * 開發時:
 *   - iOS 模擬器: localhost 直連
 *   - Android 模擬器: 10.0.2.2 (Android emulator 特殊 IP)
 *   - 實體裝置: 請改為電腦的區域 IP (如 192.168.x.x)
 *
 * 正式環境: 替換為你部署的 API 網址
 */
const DEV_API_HOST = Platform.select({
  ios: 'http://localhost:5180',
  android: 'http://10.0.2.2:5180',
  default: 'http://localhost:5180',
});

export const API_BASE_URL = __DEV__ ? DEV_API_HOST : 'https://your-production-api.com';

/**
 * API 端點路徑
 */
export const API_ENDPOINTS = {
  /** 取得近期產品行情列表 */
  products: '/api/products',
  /** 搜尋產品 */
  searchProducts: '/api/products/search',
  /** 取得特定產品詳情（需附加 /{cropName}） */
  productDetail: '/api/products',
  /** 取得分類清單 */
  categories: '/api/categories',
  /** 別名反查 */
  aliasLookup: '/api/aliases/lookup',
} as const;
