namespace VegettableApi.Services;

/// <summary>
/// 蔬菜品項依作物代號分類為五大子類別
/// 對應前端: root(根莖), leafy(葉菜), flower-fruit(花果菜), mushroom(菇菌), pickled(醃漬)
/// </summary>
public static class VegetableCategories
{
    /// <summary>
    /// 作物代號前綴 → 蔬菜子類別
    /// </summary>
    private static readonly Dictionary<string, string> CodeToSubCategory = new()
    {
        // 根莖類
        ["LA1"] = "root",    // 甘薯
        ["LA2"] = "root",    // 馬鈴薯
        ["LA3"] = "root",    // 蘿蔔
        ["LA4"] = "root",    // 胡蘿蔔
        ["LA5"] = "root",    // 牛蒡
        ["LA6"] = "root",    // 竹筍
        ["SA"] = "root",     // 根莖類統稱
        ["SB1"] = "root",    // 洋蔥
        ["SB2"] = "root",    // 大蒜
        ["SB3"] = "root",    // 薑
        ["SB4"] = "root",    // 蓮藕
        ["SB5"] = "root",    // 芋頭

        // 葉菜類
        ["LC1"] = "leafy",   // 甘藍
        ["LC2"] = "leafy",   // 小白菜
        ["LC3"] = "leafy",   // 白菜
        ["LC4"] = "leafy",   // 青江菜
        ["LC5"] = "leafy",   // 菠菜
        ["LC6"] = "leafy",   // 芹菜
        ["LC7"] = "leafy",   // 茼蒿
        ["LC8"] = "leafy",   // 莧菜
        ["LC9"] = "leafy",   // 萵苣
        ["SC"] = "leafy",    // 葉菜類統稱
        ["SD1"] = "leafy",   // 蕹菜
        ["SD2"] = "leafy",   // 油菜
        ["SD3"] = "leafy",   // 韭菜
        ["SD4"] = "leafy",   // 芥菜
        ["SD5"] = "leafy",   // 蕃薯葉

        // 花果菜類
        ["LE1"] = "flower-fruit", // 花椰菜
        ["LE2"] = "flower-fruit", // 青花菜
        ["LE3"] = "flower-fruit", // 番茄
        ["LE4"] = "flower-fruit", // 茄子
        ["LE5"] = "flower-fruit", // 甜椒
        ["LE6"] = "flower-fruit", // 辣椒
        ["SE"] = "flower-fruit",  // 花果菜統稱
        ["SF1"] = "flower-fruit", // 胡瓜
        ["SF2"] = "flower-fruit", // 絲瓜
        ["SF3"] = "flower-fruit", // 苦瓜
        ["SF4"] = "flower-fruit", // 冬瓜
        ["SF5"] = "flower-fruit", // 南瓜
        ["SF6"] = "flower-fruit", // 扁蒲
        ["SG"] = "flower-fruit",  // 豆菜類
        ["SG1"] = "flower-fruit", // 食用玉米
        ["SG2"] = "flower-fruit", // 毛豆
        ["SG3"] = "flower-fruit", // 豌豆
        ["SG4"] = "flower-fruit", // 敏豆

        // 菇菌類
        ["SH1"] = "mushroom",  // 香菇
        ["SH2"] = "mushroom",  // 洋菇
        ["SH3"] = "mushroom",  // 金針菇
        ["SH4"] = "mushroom",  // 杏鮑菇
        ["SH5"] = "mushroom",  // 秀珍菇
        ["SH6"] = "mushroom",  // 木耳

        // 醃漬類
        ["SI1"] = "pickled",  // 蘿蔔乾
        ["SI2"] = "pickled",  // 酸菜
        ["SI3"] = "pickled",  // 榨菜
        ["SI4"] = "pickled",  // 筍乾
    };

    /// <summary>由作物代號取得蔬菜子類別</summary>
    public static string? GetSubCategory(string cropCode)
    {
        if (string.IsNullOrEmpty(cropCode)) return null;

        // 先嘗試完整代號
        if (CodeToSubCategory.TryGetValue(cropCode, out var sub))
            return sub;

        // 嘗試前三碼
        if (cropCode.Length >= 3 && CodeToSubCategory.TryGetValue(cropCode[..3], out sub))
            return sub;

        // 嘗試前兩碼
        if (cropCode.Length >= 2 && CodeToSubCategory.TryGetValue(cropCode[..2], out sub))
            return sub;

        return null;
    }
}
