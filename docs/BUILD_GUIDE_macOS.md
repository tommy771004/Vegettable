# 當令蔬果生鮮 — macOS 完整建置指南

從零開始在 macOS 上建置、開發與打包此專案的完整步驟。

---

## 目錄

1. [環境需求總覽](#1-環境需求總覽)
2. [安裝 Homebrew](#2-安裝-homebrew)
3. [安裝 Node.js](#3-安裝-nodejs)
4. [安裝 .NET 8 SDK](#4-安裝-net-8-sdk)
5. [安裝 Xcode (iOS 開發)](#5-安裝-xcode-ios-開發)
6. [安裝 Android Studio (Android 開發)](#6-安裝-android-studio-android-開發)
7. [Clone 專案](#7-clone-專案)
8. [啟動後端 (.NET 8 API)](#8-啟動後端-net-8-api)
9. [啟動前端 (Expo)](#9-啟動前端-expo)
10. [在 iOS 模擬器上執行](#10-在-ios-模擬器上執行)
11. [在 Android 模擬器上執行](#11-在-android-模擬器上執行)
12. [在實體裝置上測試](#12-在實體裝置上測試)
13. [打包發布 (Production Build)](#13-打包發布-production-build)
14. [常見問題排除](#14-常見問題排除)

---

## 1. 環境需求總覽

| 工具 | 最低版本 | 用途 |
|------|----------|------|
| macOS | 13.0 (Ventura) | 開發環境 |
| Xcode | 15.0+ | iOS 模擬器 & 打包 |
| Android Studio | Hedgehog+ | Android 模擬器 & 打包 |
| Node.js | 18.0+ (建議 20 LTS) | 前端執行環境 |
| .NET SDK | 8.0+ | 後端 API |
| Git | 2.0+ | 版本控制 |

---

## 2. 安裝 Homebrew

Homebrew 是 macOS 的套件管理器，後續安裝都會用到。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

安裝完成後，依提示加入 PATH：

```bash
# Apple Silicon (M1/M2/M3/M4)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel Mac
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

驗證：
```bash
brew --version
# Homebrew 4.x.x
```

---

## 3. 安裝 Node.js

建議使用 `nvm` 管理 Node.js 版本：

```bash
# 安裝 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# 重新開啟 terminal，或執行：
source ~/.zshrc

# 安裝 Node.js 20 LTS
nvm install 20
nvm use 20
nvm alias default 20
```

驗證：
```bash
node --version   # v20.x.x
npm --version    # 10.x.x
```

---

## 4. 安裝 .NET 8 SDK

```bash
brew install dotnet@8
```

或從官網下載安裝器：
https://dotnet.microsoft.com/download/dotnet/8.0

驗證：
```bash
dotnet --version   # 8.0.xxx
dotnet --list-sdks # 應列出 8.0.xxx
```

> **注意**：若使用 Homebrew 安裝，可能需要手動加入 PATH：
> ```bash
> echo 'export PATH="/opt/homebrew/opt/dotnet@8/bin:$PATH"' >> ~/.zshrc
> source ~/.zshrc
> ```

---

## 5. 安裝 Xcode (iOS 開發)

### 5.1 安裝 Xcode

從 Mac App Store 安裝 **Xcode**（約 12GB，需要時間）。

安裝完成後，開啟 Xcode 一次，同意授權條款。

### 5.2 安裝 Command Line Tools

```bash
xcode-select --install
```

### 5.3 安裝 CocoaPods (iOS 原生依賴管理)

```bash
sudo gem install cocoapods
```

> Apple Silicon Mac 如遇到問題：
> ```bash
> brew install cocoapods
> ```

### 5.4 安裝 iOS 模擬器

開啟 Xcode → Settings → Platforms → 下載 **iOS 17** 或 **iOS 18** Simulator。

驗證：
```bash
xcrun simctl list devices available | head -20
# 應列出可用的 iPhone 模擬器
```

---

## 6. 安裝 Android Studio (Android 開發)

### 6.1 下載安裝

```bash
brew install --cask android-studio
```

或從官網下載：https://developer.android.com/studio

### 6.2 首次啟動設定

1. 開啟 Android Studio
2. 選擇 **Standard** 安裝類型
3. 等待 SDK 與工具下載完成

### 6.3 設定環境變數

```bash
cat >> ~/.zshrc << 'EOF'
# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
EOF

source ~/.zshrc
```

### 6.4 安裝 Android SDK 與模擬器

在 Android Studio 中：

1. **Settings** → **Languages & Frameworks** → **Android SDK**
2. **SDK Platforms** tab → 勾選 **Android 14 (API 34)**
3. **SDK Tools** tab → 確認以下已勾選：
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools
4. 點擊 **Apply** 安裝

### 6.5 建立 Android 模擬器

1. 開啟 Android Studio → **Virtual Device Manager**
2. 點擊 **Create Device**
3. 選擇 **Pixel 7** → **Next**
4. 選擇 **API 34** 系統映像 → 下載並 **Next**
5. 命名 (如 `Pixel_7_API_34`) → **Finish**

驗證：
```bash
adb devices
# 啟動模擬器後應列出裝置
```

---

## 7. Clone 專案

```bash
git clone https://github.com/tommy771004/Vegettable.git
cd Vegettable
```

---

## 8. 啟動後端 (.NET 8 API)

```bash
# 進入後端資料夾
cd api/VegettableApi

# 還原 NuGet 套件
dotnet restore

# 啟動（開發模式）
dotnet run
```

成功啟動後會看到：
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5180
```

### 驗證後端

另開一個 terminal：

```bash
# 健康檢查
curl http://localhost:5180/health

# 查看 Swagger 文件
open http://localhost:5180

# 測試 API
curl "http://localhost:5180/api/products?category=vegetable" | head -100
```

> **保持此 terminal 開啟**，後端需持續運行。

---

## 9. 啟動前端 (Expo)

另開一個 terminal：

```bash
# 回到專案根目錄
cd Vegettable

# 安裝 npm 套件
npm install

# 啟動 Expo 開發伺服器
npx expo start
```

成功後會看到 QR Code 和選單：

```
› Press s │ switch to Expo Go
› Press a │ open Android
› Press i │ open iOS simulator
› Press w │ open web
› Press r │ reload app
```

---

## 10. 在 iOS 模擬器上執行

在 Expo 開發伺服器的 terminal 中按 `i`：

```
› Press i │ open iOS simulator
```

首次會自動：
1. 啟動 iOS Simulator
2. 安裝 Expo Go app
3. 開啟你的 app

> **API 連線**：iOS 模擬器使用 `localhost`，已在 `constants/api.ts` 中設定好。

---

## 11. 在 Android 模擬器上執行

### 11.1 先啟動模擬器

```bash
# 列出可用模擬器
emulator -list-avds

# 啟動模擬器
emulator -avd Pixel_7_API_34
```

### 11.2 在 Expo 中開啟

在 Expo 開發伺服器的 terminal 中按 `a`：

```
› Press a │ open Android
```

> **API 連線**：Android 模擬器使用 `10.0.2.2` 存取 host 的 localhost，
> 已在 `constants/api.ts` 中設定好。

---

## 12. 在實體裝置上測試

### 12.1 安裝 Expo Go

在手機上安裝 **Expo Go** app：
- iOS: App Store 搜尋 "Expo Go"
- Android: Google Play 搜尋 "Expo Go"

### 12.2 修改 API 位址

實體裝置無法用 `localhost`，需改為你 Mac 的區域 IP：

```bash
# 查看你的 IP
ipconfig getifaddr en0
# 例如：192.168.1.100
```

修改 `constants/api.ts`：

```typescript
// 將 DEV_API_HOST 改為你的 IP
const DEV_API_HOST = 'http://192.168.1.100:5180';
```

### 12.3 掃描 QR Code

確保手機與 Mac 在同一 Wi-Fi 網路下，用 Expo Go 掃描 terminal 中的 QR Code。

---

## 13. 打包發布 (Production Build)

### 13.1 設定 EAS (Expo Application Services)

```bash
# 安裝 EAS CLI
npm install -g eas-cli

# 登入 Expo 帳號 (需先在 expo.dev 註冊)
eas login

# 初始化 EAS 設定
eas build:configure
```

### 13.2 修改正式環境 API 位址

在 `constants/api.ts` 中設定正式環境 API 網址：

```typescript
export const API_BASE_URL = __DEV__
  ? DEV_API_HOST
  : 'https://your-production-api.azurewebsites.net';  // 改為你部署的網址
```

### 13.3 打包 iOS

```bash
# 開發測試版 (不需 Apple Developer Account)
eas build --platform ios --profile development

# 正式版 (需要 Apple Developer Account, $99/年)
eas build --platform ios --profile production
```

### 13.4 打包 Android

```bash
# APK (直接安裝測試)
eas build --platform android --profile preview

# AAB (Google Play 上架)
eas build --platform android --profile production
```

### 13.5 部署後端 API

推薦部署到 Azure App Service：

```bash
cd api/VegettableApi

# 發布為 Release
dotnet publish -c Release -o ./publish

# 使用 Azure CLI 部署
az webapp up --name vegettable-api --resource-group myRG --runtime "DOTNET|8.0"
```

其他部署選項：
- **Docker** → 任何雲端
- **Railway** / **Render** → 免費方案可用
- **自建 VPS** → Nginx reverse proxy + systemd

---

## 14. 常見問題排除

### Q: `dotnet run` 時出現 SSL 憑證錯誤

```bash
dotnet dev-certs https --trust
```

### Q: iOS build 時 CocoaPods 失敗

```bash
cd ios
pod install --repo-update
cd ..
```

### Q: Android 模擬器無法連線到 API

確認 API 正在 `http://localhost:5180` 運行，Android 模擬器使用 `10.0.2.2` 對應。

```bash
# 在模擬器中測試
adb shell curl http://10.0.2.2:5180/health
```

### Q: `npx expo start` 出現 port 衝突

```bash
npx expo start --port 8082
```

### Q: Metro bundler 快取問題

```bash
npx expo start --clear
```

### Q: .NET 8 SDK 未被識別

```bash
# 確認 dotnet 在 PATH 中
which dotnet
dotnet --info

# 如果用 Homebrew 安裝
brew link dotnet@8 --force
```

### Q: Xcode Command Line Tools 問題

```bash
sudo xcode-select --reset
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Q: npm install 很慢

```bash
# 使用台灣 npm mirror
npm config set registry https://registry.npmmirror.com
npm install
# 完成後改回官方
npm config set registry https://registry.npmjs.org
```

---

## 快速啟動檢查清單

```
✅ brew --version          → Homebrew 已安裝
✅ node --version           → v18+ / v20+
✅ dotnet --version         → 8.0.xxx
✅ xcode-select -p          → /Applications/Xcode.app/...
✅ adb --version            → Android Debug Bridge
✅ pod --version             → CocoaPods 1.x.x

# 啟動順序：
1. cd api/VegettableApi && dotnet run        # Terminal 1: 後端
2. cd Vegettable && npm install && npx expo start  # Terminal 2: 前端
3. 按 i (iOS) 或 a (Android)                  # 開啟模擬器
```
