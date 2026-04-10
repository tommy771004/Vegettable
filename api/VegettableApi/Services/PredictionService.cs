using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// AI 價格預測、季節性資訊、食譜推薦服務
/// 使用簡易線性回歸 + 季節性修正做趨勢預測
/// </summary>
public class PredictionService : IPredictionService
{
    private readonly IProductService _productService;

    public PredictionService(IProductService productService)
    {
        _productService = productService;
    }

    /// <summary>
    /// 預測指定作物 7 天後均價。
    /// 流程：
    ///   1. 移除 IQR 統計異常值
    ///   2. 計算 7 日移動平均（MA7）平滑化趨勢
    ///   3. 在 MA7 序列上進行線性回歸，外推 7 天
    ///   4. 若有歷史同月資料，混合季節均值修正（回歸 65% + 季節 35%）
    ///   5. 依資料量與波動率計算信心度
    /// </summary>
    public async Task<PredictionDto> PredictPriceAsync(string cropName)
    {
        var detail = await _productService.GetProductDetailAsync(cropName);

        var rawPrices = detail.DailyPricesForPrediction.Select(d => d.AvgPrice).ToList();
        var monthlyPrices = detail.MonthlyPrices.Select(m => m.AvgPrice).ToList();

        if (rawPrices.Count < 2)
        {
            return new PredictionDto
            {
                CropName = cropName,
                CurrentPrice = detail.AvgPrice,
                PredictedPrice = detail.AvgPrice,
                ChangePercent = 0,
                Direction = "stable",
                Confidence = 20,
                Reasoning = "資料不足，無法做出有效預測",
            };
        }

        // Step 1: IQR 異常值過濾 — 移除極端離群值
        var filtered = RemoveOutliersByIQR(rawPrices);
        if (filtered.Count < 2) filtered = rawPrices; // 過濾後不足則退回原始資料

        // Step 2: MA7 移動平均平滑化（窗口不超過實際資料量）
        var windowSize = Math.Min(7, filtered.Count);
        var smoothed = ComputeMovingAverage(filtered, windowSize);

        // Step 3: 在 MA7 序列上線性回歸外推 7 天
        var n = smoothed.Count;
        var xs = Enumerable.Range(0, n).Select(i => (decimal)i).ToList();
        var xMean = xs.Average();
        var yMean = smoothed.Average();
        var denominator = xs.Select(x => (x - xMean) * (x - xMean)).Sum();
        var slope = denominator > 0
            ? xs.Zip(smoothed, (x, y) => (x - xMean) * (y - yMean)).Sum() / denominator
            : 0m;

        var predicted = yMean + slope * (n + 7 - 1);

        // Step 4: 季節性修正（混合比例調整為 65/35）
        var currentMonth = DateTime.Today.Month;
        var sameMonthPrices = detail.MonthlyPrices
            .Where(m => m.Month.EndsWith($"/{currentMonth:D2}"))
            .Select(m => m.AvgPrice)
            .ToList();

        bool hasSeasonal = sameMonthPrices.Count > 0;
        if (hasSeasonal)
        {
            var seasonalAvg = sameMonthPrices.Average();
            predicted = predicted * 0.65m + seasonalAvg * 0.35m;
        }

        predicted = Math.Max(predicted, 0.1m);
        var changePercent = detail.AvgPrice > 0
            ? Math.Round((predicted - detail.AvgPrice) / detail.AvgPrice * 100, 1)
            : 0;

        var confidence = CalculateConfidence(filtered, monthlyPrices.Count);
        // 異常值過濾有效，信心度略增
        if (filtered.Count < rawPrices.Count) confidence = Math.Min(confidence + 5, 90);

        var direction = changePercent switch
        {
            > 3 => "up",
            < -3 => "down",
            _ => "stable",
        };

        var reasoning = BuildReasoning(direction, changePercent, slope, hasSeasonal, rawPrices.Count - filtered.Count);

        return new PredictionDto
        {
            CropName = cropName,
            CurrentPrice = Math.Round(detail.AvgPrice, 1),
            PredictedPrice = Math.Round(predicted, 1),
            ChangePercent = changePercent,
            Direction = direction,
            Confidence = confidence,
            Reasoning = reasoning,
        };
    }

    /// <summary>
    /// IQR 異常值過濾：移除低於 Q1-1.5×IQR 或高於 Q3+1.5×IQR 的資料點
    /// </summary>
    private static List<decimal> RemoveOutliersByIQR(List<decimal> prices)
    {
        if (prices.Count < 4) return prices;

        var sorted = prices.OrderBy(p => p).ToList();
        var q1 = sorted[sorted.Count / 4];
        var q3 = sorted[sorted.Count * 3 / 4];
        var iqr = q3 - q1;
        var lower = q1 - 1.5m * iqr;
        var upper = q3 + 1.5m * iqr;

        return prices.Where(p => p >= lower && p <= upper).ToList();
    }

    /// <summary>
    /// 計算移動平均（MA），窗口大小 = windowSize
    /// </summary>
    private static List<decimal> ComputeMovingAverage(List<decimal> prices, int windowSize)
    {
        var result = new List<decimal>();
        for (int i = windowSize - 1; i < prices.Count; i++)
        {
            var window = prices.Skip(i - windowSize + 1).Take(windowSize);
            result.Add(window.Average());
        }
        return result.Count > 0 ? result : prices;
    }

    /// <summary>
    /// Retrieve seasonal information for crops, indicating whether each crop is currently in season.
    /// </summary>
    /// <param name="category">Optional category filter (e.g., "vegetable" or "fruit"); if null or whitespace, returns all categories.</param>
    /// <returns>A list of <see cref="SeasonalInfoDto"/> with <see cref="SeasonalInfoDto.IsInSeason"/> set based on the current month; results are ordered with in-season items first, then by crop name.</returns>
    public List<SeasonalInfoDto> GetSeasonalInfo(string? category = null)
    {
        var currentMonth = DateTime.Today.Month;

        // 建立新的副本而非修改靜態資料，避免並行請求的競態條件
        return SeasonalData
            .Where(s => string.IsNullOrWhiteSpace(category) || s.Category == category)
            .Select(s => new SeasonalInfoDto
            {
                CropName = s.CropName,
                Category = s.Category,
                PeakMonths = s.PeakMonths,
                SeasonNote = s.SeasonNote,
                IsInSeason = s.PeakMonths.Contains(currentMonth),
            })
            .OrderByDescending(s => s.IsInSeason)
            .ThenBy(s => s.CropName)
            .ToList();
    }

    /// <summary>
    /// Filters recipes to those that include the specified crop name as a substring of any ingredient (case-sensitive).
    /// </summary>
    /// <param name="cropName">The crop name or substring to match against each ingredient. An empty string will match all recipes.</param>
    /// <returns>A list of recipes whose Ingredients contain an entry that includes <paramref name="cropName"/>.</returns>
    public List<RecipeDto> GetRecipesForCrop(string cropName)
    {
        return RecipeData
            .Where(r => r.Ingredients.Any(i => i.Contains(cropName)))
            .ToList();
    }

    private static int CalculateConfidence(List<decimal> prices, int monthlyCount)
    {
        var base_ = 30;
        if (prices.Count >= 5) base_ += 20;
        if (prices.Count >= 7) base_ += 10;
        if (monthlyCount >= 12) base_ += 20;
        if (monthlyCount >= 24) base_ += 10;

        // 波動度修正 — 波動越大信心越低
        if (prices.Count >= 2)
        {
            var avg = prices.Average();
            if (avg > 0)
            {
                var volatility = prices.Select(p => Math.Abs(p - avg) / avg).Average();
                if (volatility > 0.3m) base_ -= 20;
                else if (volatility > 0.15m) base_ -= 10;
            }
        }

        return Math.Clamp(base_, 10, 90);
    }

    private static string BuildReasoning(string direction, decimal change, decimal slope, bool hasSeasonal, int removedOutliers)
    {
        var parts = new List<string>();

        if (direction == "up")
            parts.Add($"近期價格呈上漲趨勢 (預估 +{Math.Abs(change)}%)");
        else if (direction == "down")
            parts.Add($"近期價格呈下跌趨勢 (預估 -{Math.Abs(change)}%)");
        else
            parts.Add("近期價格趨於穩定");

        if (slope > 0)
            parts.Add("7日移動平均斜率向上");
        else if (slope < 0)
            parts.Add("7日移動平均斜率向下");

        if (removedOutliers > 0)
            parts.Add($"已過濾 {removedOutliers} 筆異常價格資料");

        if (hasSeasonal)
            parts.Add("已套用歷史同月季節性修正");

        parts.Add("注意：此為統計預測，僅供參考");

        return string.Join("。", parts) + "。";
    }

    // ─── 靜態資料 ────────────────────────────

    private static readonly List<SeasonalInfoDto> SeasonalData = new()
    {
        new() { CropName = "甘藍", Category = "vegetable", PeakMonths = new() { 11, 12, 1, 2, 3 }, SeasonNote = "冬季盛產，價格最低" },
        new() { CropName = "花椰菜", Category = "vegetable", PeakMonths = new() { 11, 12, 1, 2 }, SeasonNote = "冬季盛產" },
        new() { CropName = "青花菜", Category = "vegetable", PeakMonths = new() { 11, 12, 1, 2, 3 }, SeasonNote = "冬季盛產" },
        new() { CropName = "蘿蔔", Category = "vegetable", PeakMonths = new() { 11, 12, 1, 2 }, SeasonNote = "冬季盛產，品質最佳" },
        new() { CropName = "番茄", Category = "vegetable", PeakMonths = new() { 12, 1, 2, 3, 4 }, SeasonNote = "冬春盛產" },
        new() { CropName = "小白菜", Category = "vegetable", PeakMonths = new() { 10, 11, 12, 1, 2, 3 }, SeasonNote = "秋冬盛產" },
        new() { CropName = "菠菜", Category = "vegetable", PeakMonths = new() { 11, 12, 1, 2 }, SeasonNote = "冬季品質最好" },
        new() { CropName = "萵苣", Category = "vegetable", PeakMonths = new() { 10, 11, 12, 1, 2, 3 }, SeasonNote = "秋冬盛產" },
        new() { CropName = "胡瓜", Category = "vegetable", PeakMonths = new() { 4, 5, 6, 7, 8, 9 }, SeasonNote = "夏季盛產" },
        new() { CropName = "絲瓜", Category = "vegetable", PeakMonths = new() { 5, 6, 7, 8, 9 }, SeasonNote = "夏季盛產" },
        new() { CropName = "苦瓜", Category = "vegetable", PeakMonths = new() { 5, 6, 7, 8, 9 }, SeasonNote = "夏季盛產" },
        new() { CropName = "茄子", Category = "vegetable", PeakMonths = new() { 4, 5, 6, 7, 8, 9, 10 }, SeasonNote = "春夏秋皆產" },
        new() { CropName = "青椒", Category = "vegetable", PeakMonths = new() { 10, 11, 12, 1, 2, 3 }, SeasonNote = "秋冬盛產" },
        new() { CropName = "洋蔥", Category = "vegetable", PeakMonths = new() { 3, 4, 5 }, SeasonNote = "春季盛產" },
        new() { CropName = "大蒜", Category = "vegetable", PeakMonths = new() { 3, 4, 5 }, SeasonNote = "春季盛產" },
        new() { CropName = "竹筍", Category = "vegetable", PeakMonths = new() { 5, 6, 7, 8 }, SeasonNote = "夏季盛產" },
        new() { CropName = "玉米", Category = "vegetable", PeakMonths = new() { 7, 8, 9, 10, 11 }, SeasonNote = "夏秋盛產" },
        new() { CropName = "甘薯", Category = "vegetable", PeakMonths = new() { 8, 9, 10, 11, 12 }, SeasonNote = "秋冬盛產" },
        new() { CropName = "馬鈴薯", Category = "vegetable", PeakMonths = new() { 2, 3, 4, 12 }, SeasonNote = "冬春盛產" },
        new() { CropName = "芒果", Category = "fruit", PeakMonths = new() { 5, 6, 7, 8 }, SeasonNote = "夏季盛產" },
        new() { CropName = "西瓜", Category = "fruit", PeakMonths = new() { 5, 6, 7, 8 }, SeasonNote = "夏季盛產" },
        new() { CropName = "荔枝", Category = "fruit", PeakMonths = new() { 6, 7 }, SeasonNote = "初夏短期盛產" },
        new() { CropName = "龍眼", Category = "fruit", PeakMonths = new() { 7, 8 }, SeasonNote = "夏季盛產" },
        new() { CropName = "柳丁", Category = "fruit", PeakMonths = new() { 11, 12, 1, 2 }, SeasonNote = "冬季盛產" },
        new() { CropName = "香蕉", Category = "fruit", PeakMonths = new() { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }, SeasonNote = "全年盛產" },
        new() { CropName = "鳳梨", Category = "fruit", PeakMonths = new() { 3, 4, 5, 6, 7 }, SeasonNote = "春夏盛產" },
        new() { CropName = "釋迦", Category = "fruit", PeakMonths = new() { 8, 9, 10, 11, 12, 1, 2 }, SeasonNote = "秋冬盛產" },
        new() { CropName = "蓮霧", Category = "fruit", PeakMonths = new() { 11, 12, 1, 2, 3 }, SeasonNote = "冬春盛產" },
        new() { CropName = "芭樂", Category = "fruit", PeakMonths = new() { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }, SeasonNote = "全年盛產" },
        new() { CropName = "木瓜", Category = "fruit", PeakMonths = new() { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }, SeasonNote = "全年盛產" },
        new() { CropName = "葡萄", Category = "fruit", PeakMonths = new() { 6, 7, 8, 12, 1 }, SeasonNote = "夏季及冬季盛產" },
        new() { CropName = "草莓", Category = "fruit", PeakMonths = new() { 12, 1, 2, 3 }, SeasonNote = "冬春盛產" },
    };

    private static readonly List<RecipeDto> RecipeData = new()
    {
        new() { Name = "高麗菜水餃", Description = "經典家常料理，皮薄餡多", Ingredients = new() { "甘藍", "豬肉", "蔥", "薑" }, Difficulty = "medium", CookTimeMinutes = 60 },
        new() { Name = "清炒高麗菜", Description = "簡單快速的家常菜", Ingredients = new() { "甘藍", "蒜", "油" }, Difficulty = "easy", CookTimeMinutes = 10 },
        new() { Name = "番茄炒蛋", Description = "國民家常菜", Ingredients = new() { "番茄", "雞蛋", "蔥" }, Difficulty = "easy", CookTimeMinutes = 15 },
        new() { Name = "番茄牛肉麵", Description = "濃郁番茄湯頭配牛肉", Ingredients = new() { "番茄", "牛腩", "麵條", "洋蔥" }, Difficulty = "hard", CookTimeMinutes = 120 },
        new() { Name = "蒜泥白肉", Description = "涼拌下酒菜", Ingredients = new() { "大蒜", "五花肉", "小黃瓜" }, Difficulty = "medium", CookTimeMinutes = 30 },
        new() { Name = "涼拌小黃瓜", Description = "夏日開胃小菜", Ingredients = new() { "胡瓜", "蒜", "辣椒", "醋" }, Difficulty = "easy", CookTimeMinutes = 10 },
        new() { Name = "絲瓜蛤蠣湯", Description = "鮮甜清爽的家常湯品", Ingredients = new() { "絲瓜", "蛤蠣", "薑" }, Difficulty = "easy", CookTimeMinutes = 20 },
        new() { Name = "苦瓜鹹蛋", Description = "苦甘回甘的經典搭配", Ingredients = new() { "苦瓜", "鹹蛋", "蒜" }, Difficulty = "easy", CookTimeMinutes = 15 },
        new() { Name = "竹筍排骨湯", Description = "清甜鮮美的煲湯", Ingredients = new() { "竹筍", "排骨", "薑" }, Difficulty = "medium", CookTimeMinutes = 60 },
        new() { Name = "蘿蔔燉牛腩", Description = "冬季暖身燉菜", Ingredients = new() { "蘿蔔", "牛腩", "蔥", "薑" }, Difficulty = "medium", CookTimeMinutes = 90 },
        new() { Name = "菠菜豆腐湯", Description = "營養清爽的日常湯品", Ingredients = new() { "菠菜", "豆腐", "薑" }, Difficulty = "easy", CookTimeMinutes = 15 },
        new() { Name = "地瓜粥", Description = "古早味地瓜甜粥", Ingredients = new() { "甘薯", "白米", "糖" }, Difficulty = "easy", CookTimeMinutes = 40 },
        new() { Name = "塔香茄子", Description = "九層塔茄子快炒", Ingredients = new() { "茄子", "九層塔", "蒜", "辣椒" }, Difficulty = "easy", CookTimeMinutes = 15 },
        new() { Name = "洋蔥炒牛肉", Description = "甜嫩多汁的快炒料理", Ingredients = new() { "洋蔥", "牛肉", "醬油" }, Difficulty = "easy", CookTimeMinutes = 15 },
        new() { Name = "芒果冰沙", Description = "夏日消暑冰品", Ingredients = new() { "芒果", "冰塊", "煉乳" }, Difficulty = "easy", CookTimeMinutes = 5 },
        new() { Name = "鳳梨蝦球", Description = "酸甜可口的宴客菜", Ingredients = new() { "鳳梨", "蝦仁", "美乃滋" }, Difficulty = "medium", CookTimeMinutes = 25 },
        new() { Name = "玉米濃湯", Description = "香甜濃郁的西式湯品", Ingredients = new() { "玉米", "奶油", "牛奶" }, Difficulty = "easy", CookTimeMinutes = 20 },
        new() { Name = "馬鈴薯燉肉", Description = "日式風味燉煮料理", Ingredients = new() { "馬鈴薯", "豬肉", "洋蔥", "紅蘿蔔" }, Difficulty = "medium", CookTimeMinutes = 45 },
        new() { Name = "青椒炒肉絲", Description = "經典便當菜", Ingredients = new() { "青椒", "豬肉", "醬油" }, Difficulty = "easy", CookTimeMinutes = 15 },
        new() { Name = "花椰菜炒蝦仁", Description = "清爽營養的海鮮料理", Ingredients = new() { "花椰菜", "蝦仁", "蒜" }, Difficulty = "easy", CookTimeMinutes = 15 },
    };
}
