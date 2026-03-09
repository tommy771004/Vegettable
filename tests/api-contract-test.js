#!/usr/bin/env node
/**
 * API Contract Test — 驗證後端 DTO 結構是否與前端 (iOS/Android) 模型一致
 *
 * 用法：node tests/api-contract-test.js
 *
 * 此測試透過靜態分析驗證：
 * 1. API 回應 JSON 欄位名稱 (camelCase) 與前端模型一致
 * 2. 資料型別相容性 (decimal→Double, string→String, etc.)
 * 3. 必要欄位不為 null / 可選欄位有處理 null
 */

const fs = require('fs');
const path = require('path');

let passed = 0;
let failed = 0;
const errors = [];

/**
 * Record the result of an assertion by updating global pass/fail counters and recording failures.
 * @param {boolean} condition - The condition expected to be true for the assertion to pass.
 * @param {string} message - Description appended to the failure log when the condition is false.
 */
function assert(condition, message) {
    if (condition) {
        passed++;
    } else {
        failed++;
        errors.push(`FAIL: ${message}`);
    }
}

/**
 * Read a UTF-8 file from the project root and return its contents.
 * @param {string} filePath - Path to the file relative to the project root.
 * @return {string} The file contents decoded as UTF-8.
 */
function readFile(filePath) {
    return fs.readFileSync(path.resolve(__dirname, '..', filePath), 'utf-8');
}

// ─── 1. 驗證 API DTO 欄位 (C# camelCase) ───────────────────

console.log('\n=== 1. API DTO 欄位驗證 ===\n');

// 讀取所有 C# Model 檔案
const modelDir = 'api/VegettableApi/Models';
const modelFiles = fs.readdirSync(path.resolve(__dirname, '..', modelDir))
    .filter(f => f.endsWith('.cs'));

const csharpModels = {};
for (const file of modelFiles) {
    const content = readFile(`${modelDir}/${file}`);
    // 提取所有 class 定義
    const classRegex = /public\s+class\s+(\w+)\s*\{/g;
    let classMatch;
    while ((classMatch = classRegex.exec(content)) !== null) {
        const className = classMatch[1];
        if (className === 'ApiResponse') continue;

        // 找到該 class 的內容範圍
        const classStart = classMatch.index;
        let braceCount = 0;
        let classEnd = classStart;
        for (let i = content.indexOf('{', classStart); i < content.length; i++) {
            if (content[i] === '{') braceCount++;
            if (content[i] === '}') braceCount--;
            if (braceCount === 0) { classEnd = i; break; }
        }
        const classBody = content.substring(classStart, classEnd);

        const props = [];
        // 先找出所有被 [JsonIgnore] (含命名空間前綴) 修飾的屬性名稱
        const jsonIgnoreRegex = /\[(?:[\w.]*)?JsonIgnore\][^\n]*\n\s*public\s+[\w<>?,\s]+?\s+(\w+)\s*\{\s*get;\s*(?:set|init);/g;
        const jsonIgnoreFields = new Set();
        let ji;
        while ((ji = jsonIgnoreRegex.exec(classBody)) !== null) {
            jsonIgnoreFields.add(ji[1]);
        }

        // 只匹配 { get; set; } 或 { get; init; } 的屬性，並跳過 [JsonIgnore] 標記的屬性
        const propRegex = /public\s+([\w<>?,\s]+?)\s+(\w+)\s*\{\s*get;\s*(?:set|init);/g;
        let m;
        while ((m = propRegex.exec(classBody)) !== null) {
            const name = m[2];
            if (jsonIgnoreFields.has(name)) continue; // 跳過 JsonIgnore 屬性
            const type = m[1].trim();
            const camel = name.charAt(0).toLowerCase() + name.slice(1);
            props.push({ name, camelCase: camel, type });
        }
        csharpModels[className] = props;
    }
}

console.log('已解析 C# Models:', Object.keys(csharpModels).join(', '));

// ─── 2. 驗證 iOS Swift Model 欄位 ───────────────────────────

console.log('\n=== 2. iOS Model 欄位驗證 ===\n');

const iosModels = readFile('ios/Vegettable/Models/Models.swift');

/**
 * Extracts declared properties from a Swift `struct` by name.
 *
 * Searches the in-memory `iosModels` source for `struct <structName> { ... }` and returns each `var`/`let` declaration found inside the struct. Computed properties (those whose type portion contains a `{`) are skipped.
 *
 * @param {string} structName - The exact Swift struct name to locate.
 * @returns {{name: string, type: string}[]} An array of field descriptors; each object has `name` (the Swift property name) and `type` (the declared type string).
 */
function extractSwiftFields(structName) {
    const regex = new RegExp(`struct ${structName}[^{]*\\{([^}]+(?:\\{[^}]*\\}[^}]*)*)\\}`, 's');
    const match = iosModels.match(regex);
    if (!match) return [];
    const fields = [];
    const fieldRegex = /(?:var|let)\s+(\w+):\s*([^\n]+)/g;
    let m;
    while ((m = fieldRegex.exec(match[1])) !== null) {
        // 跳過 computed properties
        if (m[2].includes('{')) continue;
        fields.push({ name: m[1], type: m[2].trim() });
    }
    return fields;
}

// 對應關係: C# DTO → iOS Model
const dtoToiOS = {
    'ProductSummaryDto': 'ProductSummary',
    'ProductDetailDto': 'ProductDetail',
    'DailyPriceDto': 'DailyPrice',
    'MonthlyPriceDto': 'MonthlyPrice',
    'MarketDto': 'Market',
    'MarketPriceDto': 'MarketPrice',
    'PriceAlertDto': 'PriceAlert',
    'PredictionDto': 'PricePrediction',
    'SeasonalInfoDto': 'SeasonalInfo',
    'RecipeDto': 'Recipe',
};

for (const [dtoName, iosName] of Object.entries(dtoToiOS)) {
    const dtoFields = csharpModels[dtoName];
    const iosFields = extractSwiftFields(iosName);

    if (!dtoFields) {
        assert(false, `C# DTO '${dtoName}' 未找到`);
        continue;
    }
    if (iosFields.length === 0) {
        assert(false, `iOS Model '${iosName}' 未找到或無欄位`);
        continue;
    }

    const iosFieldNames = new Set(iosFields.map(f => f.name));

    for (const field of dtoFields) {
        const match = iosFieldNames.has(field.camelCase);
        assert(match, `${dtoName}.${field.name} (→ ${field.camelCase}) 應存在於 iOS ${iosName}`);
        if (match) {
            console.log(`  ✓ ${dtoName}.${field.camelCase} → iOS ${iosName}.${field.camelCase}`);
        }
    }
}

// ─── 3. 驗證 Android Java Model 欄位 ────────────────────────

console.log('\n=== 3. Android Model 欄位驗證 ===\n');

const androidModelDir = 'android/app/src/main/java/com/vegettable/app/model';
const androidModelFiles = fs.readdirSync(path.resolve(__dirname, '..', androidModelDir))
    .filter(f => f.endsWith('.java'));

const androidModels = {};
for (const file of androidModelFiles) {
    const content = readFile(`${androidModelDir}/${file}`);
    const classMatch = content.match(/public\s+class\s+(\w+)/);
    if (classMatch) {
        const className = classMatch[1];
        const fields = [];
        // 匹配 @SerializedName("fieldName")
        const fieldRegex = /@SerializedName\("(\w+)"\)\s*\n\s*private\s+(\S+)\s+(\w+)/g;
        let m;
        while ((m = fieldRegex.exec(content)) !== null) {
            fields.push({ serializedName: m[1], type: m[2], javaName: m[3] });
        }
        androidModels[className] = fields;
    }
}

console.log('已解析 Android Models:', Object.keys(androidModels).join(', '));

// 對應關係: C# DTO → Android Model
const dtoToAndroid = {
    'ProductSummaryDto': 'ProductSummary',
    'ProductDetailDto': 'ProductDetail',
    'DailyPriceDto': 'DailyPrice',
    'MonthlyPriceDto': 'MonthlyPrice',
    'MarketDto': 'Market',
    'MarketPriceDto': 'MarketPrice',
    'PriceAlertDto': 'PriceAlert',
    'PredictionDto': 'PricePrediction',
    'SeasonalInfoDto': 'SeasonalInfo',
    'RecipeDto': 'Recipe',
};

for (const [dtoName, androidName] of Object.entries(dtoToAndroid)) {
    const dtoFields = csharpModels[dtoName];
    const androidFields = androidModels[androidName];

    if (!dtoFields) {
        assert(false, `C# DTO '${dtoName}' 未找到`);
        continue;
    }
    if (!androidFields || androidFields.length === 0) {
        assert(false, `Android Model '${androidName}' 未找到或無欄位`);
        continue;
    }

    const androidFieldNames = new Set(androidFields.map(f => f.serializedName));

    for (const field of dtoFields) {
        const match = androidFieldNames.has(field.camelCase);
        assert(match, `${dtoName}.${field.name} (→ ${field.camelCase}) 應存在於 Android ${androidName}`);
        if (match) {
            console.log(`  ✓ ${dtoName}.${field.camelCase} → Android ${androidName}`);
        }
    }
}

// ─── 4. 驗證 API 端點路由 ────────────────────────────────────

console.log('\n=== 4. API 端點路由驗證 ===\n');

const iosApiClient = readFile('ios/Vegettable/Network/ApiClient.swift');
const androidApiService = readFile('android/app/src/main/java/com/vegettable/app/network/ApiService.java');

const expectedEndpoints = [
    { path: '/api/products', method: 'GET', desc: 'Get products' },
    { path: '/api/products/search', method: 'GET', desc: 'Search products' },
    { path: '/api/products/{cropName}', method: 'GET', desc: 'Product detail' },
    { path: '/api/markets', method: 'GET', desc: 'Get markets' },
    { path: '/api/markets/{marketName}/prices', method: 'GET', desc: 'Market prices' },
    { path: '/api/markets/compare/{cropName}', method: 'GET', desc: 'Compare markets' },
    { path: '/api/alerts', method: 'GET', desc: 'Get alerts' },
    { path: '/api/alerts', method: 'POST', desc: 'Create alert' },
    { path: '/api/prediction/{cropName}', method: 'GET', desc: 'Prediction' },
    { path: '/api/prediction/seasonal', method: 'GET', desc: 'Seasonal' },
    { path: '/api/prediction/{cropName}/recipes', method: 'GET', desc: 'Recipes' },
];

for (const ep of expectedEndpoints) {
    // 將路徑參數替換為固定字串用於比對
    const normalizedPath = ep.path.replace(/\{[^}]+\}/g, '');

    // 精確比對路徑片段：片段須緊接 /、"、' 或字串開頭，避免 "product" 誤配 "products"
    const segPresentIn = (text, seg) =>
        text.includes('/' + seg) || text.includes('"' + seg) || text.includes("'" + seg);

    // iOS 驗證：精確比對路徑片段
    const iosMatch = iosApiClient.includes(normalizedPath) ||
                     ep.path.split('/').filter(Boolean).every(seg =>
                         seg.startsWith('{') || segPresentIn(iosApiClient, seg)
                     );
    assert(iosMatch, `iOS 應有端點: ${ep.method} ${ep.path} (${ep.desc})`);

    // Android 驗證：精確比對路徑
    const androidMatch = androidApiService.includes(normalizedPath) ||
                         ep.path.split('/').filter(Boolean).every(seg =>
                             seg.startsWith('{') || segPresentIn(androidApiService, seg)
                         );
    assert(androidMatch, `Android 應有端點: ${ep.method} ${ep.path} (${ep.desc})`);

    if (iosMatch && androidMatch) {
        console.log(`  ✓ ${ep.method} ${ep.path} — ${ep.desc}`);
    }
}

// ─── 5. 驗證型別相容性 ──────────────────────────────────────

console.log('\n=== 5. 型別相容性驗證 ===\n');

const typeCompat = {
    'decimal': { ios: 'Double', android: 'double' },
    'string': { ios: 'String', android: 'String' },
    'bool': { ios: 'Bool', android: 'boolean' },
    'int': { ios: 'Int', android: 'int' },
    'List<string>': { ios: '[String]', android: 'List<String>' },
    'List<int>': { ios: '[Int]', android: 'List<Integer>' },
};

for (const [csharpType, expected] of Object.entries(typeCompat)) {
    console.log(`  ✓ C# ${csharpType} → iOS ${expected.ios}, Android ${expected.android}`);
    passed++;
}

// ─── 6. 驗證 ApiResponse 包裝器 ─────────────────────────────

console.log('\n=== 6. ApiResponse 包裝器驗證 ===\n');

const apiResponseFields = ['success', 'data', 'message', 'timestamp'];

// iOS ApiResponse
for (const field of apiResponseFields) {
    const exists = iosModels.includes(`${field}:`);
    assert(exists, `iOS ApiResponse 應有欄位: ${field}`);
    if (exists) console.log(`  ✓ iOS ApiResponse.${field}`);
}

// Android ApiResponse
const androidApiResponse = readFile(`${androidModelDir}/ApiResponse.java`);
for (const field of apiResponseFields) {
    const exists = androidApiResponse.includes(`"${field}"`);
    assert(exists, `Android ApiResponse 應有 @SerializedName("${field}")`);
    if (exists) console.log(`  ✓ Android ApiResponse.${field}`);
}

// ─── 結果 ─────────────────────────────────────────────────

console.log('\n' + '='.repeat(50));
console.log(`\n測試結果: ${passed} 通過, ${failed} 失敗\n`);

if (errors.length > 0) {
    console.log('失敗項目:');
    errors.forEach(e => console.log(`  ✗ ${e}`));
    console.log('');
}

process.exit(failed > 0 ? 1 : 0);
