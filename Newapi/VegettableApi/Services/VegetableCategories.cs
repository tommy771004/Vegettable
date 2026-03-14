using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 蔬果分類對照表
/// </summary>
public static class VegetableCategories
{
    private static readonly Dictionary<string, string> CategoryMap = new()
    {
        // 根莖類
        ["甘薯"] = "rootVegetable",
        ["馬鈴薯"] = "rootVegetable",
        ["蘿蔔"] = "rootVegetable",
        ["胡蘿蔔"] = "rootVegetable",
        ["竹筍"] = "rootVegetable",
        ["洋蔥"] = "rootVegetable",
        ["大蒜"] = "rootVegetable",
        ["薑"] = "rootVegetable",
        ["芋頭"] = "rootVegetable",
        ["蓮藕"] = "rootVegetable",
        ["牛蒡"] = "rootVegetable",

        // 葉菜類
        ["甘藍"] = "leafy",
        ["小白菜"] = "leafy",
        ["白菜"] = "leafy",
        ["青江菜"] = "leafy",
        ["芹菜"] = "leafy",
        ["菠菜"] = "leafy",
        ["茼蒿"] = "leafy",
        ["莧菜"] = "leafy",
        ["萵苣"] = "leafy",
        ["蕹菜"] = "leafy",
        ["油菜"] = "leafy",
        ["韭菜"] = "leafy",
        ["芥菜"] = "leafy",
        ["蕃薯葉"] = "leafy",

        // 花果菜類
        ["花椰菜"] = "cruciferous",
        ["青花菜"] = "cruciferous",
        ["番茄"] = "fruity",
        ["茄子"] = "fruity",
        ["甜椒"] = "fruity",
        ["辣椒"] = "fruity",
        ["胡瓜"] = "fruity",
        ["絲瓜"] = "fruity",
        ["苦瓜"] = "fruity",
        ["冬瓜"] = "fruity",
        ["南瓜"] = "fruity",
        ["扁蒲"] = "fruity",
        ["食用玉米"] = "fruity",
        ["毛豆"] = "legume",
        ["豌豆"] = "legume",
        ["敏豆"] = "legume",

        // 菇菌類
        ["香菇"] = "mushroom",
        ["洋菇"] = "mushroom",
        ["金針菇"] = "mushroom",
        ["杏鮑菇"] = "mushroom",
        ["秀珍菇"] = "mushroom",
        ["木耳"] = "mushroom",

        // 水果
        ["香蕉"] = "fruit",
        ["鳳梨"] = "fruit",
        ["西瓜"] = "fruit",
        ["木瓜"] = "fruit",
        ["芒果"] = "fruit",
        ["荔枝"] = "fruit",
        ["龍眼"] = "fruit",
        ["番石榴"] = "fruit",
        ["蓮霧"] = "fruit",
        ["柳橙"] = "fruit",
        ["椪柑"] = "fruit",
        ["葡萄"] = "fruit",
        ["梨"] = "fruit",
        ["棗"] = "fruit",
        ["釋迦"] = "fruit",
        ["百香果"] = "fruit",
        ["火龍果"] = "fruit",
        ["檸檬"] = "fruit",
        ["酪梨"] = "fruit",
        ["草莓"] = "fruit",

        // 肉品
        ["毛豬"] = "meat",
        ["白肉雞"] = "meat",
        ["紅羽土雞"] = "meat",
        ["雞蛋"] = "egg",
    };

    private static readonly Dictionary<string, string> CategoryDisplayNames = new()
    {
        ["rootVegetable"] = "根莖類",
        ["leafy"] = "葉菜類",
        ["cruciferous"] = "花菜類",
        ["fruity"] = "瓜果類",
        ["legume"] = "豆類",
        ["mushroom"] = "菇菌類",
        ["fruit"] = "水果",
        ["meat"] = "肉品",
        ["egg"] = "蛋品",
    };

    /// <summary>取得品項的分類</summary>
    public static string GetCategory(string cropName)
    {
        return CategoryMap.GetValueOrDefault(cropName, "other");
    }

    /// <summary>取得所有分類清單及其品項數</summary>
    public static List<CategoryDto> GetCategories()
    {
        var grouped = CategoryMap
            .GroupBy(kvp => kvp.Value)
            .Select(g => new CategoryDto
            {
                Category = g.Key,
                DisplayName = CategoryDisplayNames.GetValueOrDefault(g.Key, g.Key),
                Count = g.Count(),
            })
            .OrderBy(c => c.DisplayName)
            .ToList();

        return grouped;
    }
}
