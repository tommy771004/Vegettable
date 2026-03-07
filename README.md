# Vegettable

當令蔬果生鮮 -- 查詢台灣當季蔬菜、水果、漁產、肉品、花卉、白米的平均批發價

## 專案架構

```
Vegettable/
├── android/          ← Android 原生專案 (Java)
├── ios/              ← iOS 原生專案 (Swift/SwiftUI)
├── api/              ← .NET 8 後端 API (C#)
└── docs/             ← 文件
```

## 功能特色

- 即時蔬果行情（農委會每日交易行情資料）
- 四等級價格指標（當令便宜 → 相對偏貴）
- 近 7 日價格走勢 + 近 3 年月均價
- AI 價格預測（線性迴歸 + 季節校正）
- 季節行事曆（各作物盛產月份）
- 市場比價（全台 15 個批發市場交叉比較）
- 批發市場地圖（13 處市場含一鍵導航）
- 價格警示（自訂門檻推播通知）
- 食譜推薦
- 收藏常買品項
- 公斤/台斤切換、批發/零售估價
- 離線快取

## 後端 API

```bash
cd api/VegettableApi
dotnet run
# API 啟動於 http://localhost:5180
```

### API 端點

| 端點 | 方法 | 說明 |
|------|------|------|
| `/api/products` | GET | 產品行情列表 |
| `/api/products/search?keyword=` | GET | 搜尋產品 |
| `/api/products/{cropName}` | GET | 產品詳細價格歷史 |
| `/api/markets` | GET | 批發市場清單 |
| `/api/markets/{name}/prices` | GET | 指定市場行情 |
| `/api/markets/compare/{crop}` | GET | 多市場比價 |
| `/api/alerts` | GET/POST | 價格警示 CRUD |
| `/api/alerts/{id}` | DELETE | 刪除警示 |
| `/api/alerts/{id}/toggle` | PATCH | 開關警示 |
| `/api/prediction/{crop}` | GET | AI 價格預測 |
| `/api/prediction/seasonal` | GET | 季節性資訊 |
| `/api/prediction/{crop}/recipes` | GET | 食譜推薦 |

## Android 開發

```bash
# 使用 Android Studio 開啟 android/ 目錄
# 最低 SDK: 26 (Android 8.0)
# 目標 SDK: 34 (Android 14)
# 語言: Java 17
# 依賴: Retrofit, Gson, Material Design 3, RecyclerView
```

## iOS 開發

```bash
# 使用 Xcode 開啟 ios/Vegettable.xcodeproj
# 最低版本: iOS 16.0
# 語言: Swift 5 + SwiftUI
# 無第三方依賴，純原生開發
```

## 資料來源

- 農委會：農產品交易行情、漁產品交易行情、家禽交易行情
- 農糧署：白米價格
