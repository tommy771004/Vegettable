export default {
  // Tab bar
  tab_home: '當令行情',
  tab_search: '搜尋',
  tab_favorites: '常買清單',
  tab_settings: '設定',

  // Home
  home_subtitle: '找到最划算的蔬果生鮮',
  home_loading: '載入行情中...',
  home_error: '載入失敗',
  home_retry: '點擊重試',
  home_empty: '目前沒有此類別的產品資料',

  // Search
  search_title: '搜尋',
  search_subtitle: '輸入品名或別名查詢',
  search_placeholder: '搜尋蔬果...',
  search_tip_title: '搜尋小技巧',
  search_tip_text: '支援別名搜尋！例如輸入「地瓜」可找到「甘薯」，輸入「高麗菜」可找到「甘藍」。',
  search_not_found: '找不到「{keyword}」相關品項',
  search_try_other: '試試其他名稱或別名',
  search_result_count: '共找到 {count} 項結果',

  // Favorites
  fav_title: '常買清單',
  fav_empty_title: '還沒有常買品項',
  fav_empty_subtitle: '在行情頁點愛心加入常買清單，方便追蹤價格變化。',

  // Settings
  settings_title: '設定',
  settings_price_unit: '價格單位',
  settings_per_kg: '每公斤',
  settings_per_catty: '每台斤',
  settings_show_retail: '顯示零售估價',
  settings_retail_note: '以批發價 × 2.5 估算零售價',
  settings_dark_mode: '深色模式',
  settings_dark_system: '跟隨系統',
  settings_dark_light: '淺色',
  settings_dark_dark: '深色',
  settings_language: '語言',
  settings_market: '預設市場',
  settings_market_all: '全台平均',
  settings_alerts: '價格警示',
  settings_about: '關於',
  settings_disclaimer: '資料來源：農業部農產品交易開放資料平臺。價格為全台批發市場加權平均，僅供參考。',

  // Detail
  detail_daily_chart: '近七日均價走勢 (元/公斤)',
  detail_monthly_chart: '近三年月均價趨勢 (元/公斤)',
  detail_wholesale: '批發均價',
  detail_retail: '零售估價',
  detail_vs_history: '較歷史均價',
  detail_share: '分享',
  detail_prediction: 'AI 價格預測',
  detail_recipes: '推薦食譜',
  detail_set_alert: '設定價格警示',
  detail_fallback: '詳細資料暫時無法取得，顯示近期概況',

  // Price levels
  level_very_cheap: '當令便宜',
  level_cheap: '相對便宜',
  level_normal: '正常偏貴',
  level_expensive: '偏貴',

  // Prediction
  predict_up: '預測上漲',
  predict_down: '預測下跌',
  predict_stable: '預測持平',
  predict_confidence: '信心度',

  // Seasonal
  seasonal_title: '當季蔬果日曆',
  seasonal_in_season: '當季',
  seasonal_off_season: '非當季',

  // Markets
  market_compare: '市場價格比較',
  market_north: '北部',
  market_central: '中部',
  market_south: '南部',
  market_east: '東部',

  // Alerts
  alert_title: '價格警示',
  alert_add: '新增警示',
  alert_below: '低於',
  alert_above: '高於',
  alert_per_kg: '元/公斤',
  alert_delete: '刪除',
  alert_empty: '尚未設定任何警示',

  // Common
  common_loading: '載入中...',
  common_retry: '重試',
  common_cancel: '取消',
  common_confirm: '確認',
  common_save: '儲存',
  common_share: '分享',
  common_volume: '交易量',
  common_ton: '公噸',
} as const;
