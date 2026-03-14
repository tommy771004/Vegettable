namespace VegettableApi.Services;

/// <summary>
/// 作物別名對照表 — 常用俗稱對應官方名稱
/// 如："地瓜" -> "甘薯", "番薯" -> "甘薯" 等
/// </summary>
public static class CropAliases
{
    private static readonly Dictionary<string, string> AliasToOfficial = new(StringComparer.OrdinalIgnoreCase)
    {
        // 根莖類
        ["地瓜"] = "甘薯",
        ["番薯"] = "甘薯",
        ["蕃薯"] = "甘薯",
        ["白薯"] = "甘薯",
        ["紅薯"] = "甘薯",
        ["馬鈴"] = "馬鈴薯",
        ["土豆"] = "馬鈴薯",
        ["洋山芋"] = "馬鈴薯",
        ["白蘿蔔"] = "蘿蔔",
        ["紅蘿蔔"] = "胡蘿蔔",
        ["胡蘿"] = "胡蘿蔔",
        ["番蘿蔔"] = "胡蘿蔔",

        // 葉菜類
        ["高麗菜"] = "甘藍",
        ["包菜"] = "甘藍",
        ["結球甘藍"] = "甘藍",
        ["小白"] = "小白菜",
        ["小白菜"] = "小白菜",
        ["白菜"] = "白菜",
        ["結球白菜"] = "白菜",
        ["青江"] = "青江菜",
        ["小松菜"] = "青江菜",
        ["菠菜"] = "菠菜",
        ["波菜"] = "菠菜",
        ["芹菜"] = "芹菜",
        ["西芹"] = "芹菜",
        ["茼蒿"] = "茼蒿",
        ["蓬蒿"] = "茼蒿",
        ["莧菜"] = "莧菜",
        ["紅莧"] = "莧菜",
        ["生菜"] = "萵苣",
        ["生菜"] = "萵苣",
        ["蕹菜"] = "蕹菜",
        ["空心菜"] = "蕹菜",
        ["油菜"] = "油菜",
        ["韭菜"] = "韭菜",
        ["韭"] = "韭菜",
        ["芥菜"] = "芥菜",
        ["梅菜"] = "芥菜",

        // 花果菜類
        ["花椰菜"] = "花椰菜",
        ["花菜"] = "花椰菜",
        ["白花菜"] = "花椰菜",
        ["青花菜"] = "青花菜",
        ["綠花菜"] = "青花菜",
        ["西蘭花"] = "青花菜",
        ["番茄"] = "番茄",
        ["蕃茄"] = "番茄",
        ["西紅柿"] = "番茄",
        ["茄子"] = "茄子",
        ["長茄"] = "茄子",
        ["甜椒"] = "甜椒",
        ["彩椒"] = "甜椒",
        ["甜辣椒"] = "甜椒",
        ["辣椒"] = "辣椒",
        ["紅辣椒"] = "辣椒",
        ["朝天椒"] = "辣椒",
        ["小黃瓜"] = "胡瓜",
        ["黃瓜"] = "胡瓜",
        ["鮮黃瓜"] = "胡瓜",
        ["絲瓜"] = "絲瓜",
        ["絲瓜"] = "絲瓜",
        ["苦瓜"] = "苦瓜",
        ["冬瓜"] = "冬瓜",
        ["南瓜"] = "南瓜",
        ["扁蒲"] = "扁蒲",
        ["毛豆"] = "毛豆",
        ["青豆"] = "毛豆",
        ["豌豆"] = "豌豆",
        ["荷蘭豆"] = "豌豆",
        ["玉米"] = "食用玉米",
        ["玉"] = "食用玉米",
        ["敏豆"] = "敏豆",
        ["豆角"] = "敏豆",

        // 菇菌類
        ["香菇"] = "香菇",
        ["冬菇"] = "香菇",
        ["洋菇"] = "洋菇",
        ["蘑菇"] = "洋菇",
        ["草菇"] = "洋菇",
        ["金針菇"] = "金針菇",
        ["杏鮑菇"] = "杏鮑菇",
        ["秀珍菇"] = "秀珍菇",
        ["木耳"] = "木耳",
        ["黑木耳"] = "木耳",

        // 醃漬類
        ["蘿蔔乾"] = "蘿蔔乾",
        ["酸菜"] = "酸菜",
        ["榨菜"] = "榨菜",
        ["筍乾"] = "筍乾",

        // 水果
        ["蘋果"] = "蘋果",
        ["香蕉"] = "香蕉",
        ["橘子"] = "橘子",
        ["柳丁"] = "柳丁",
        ["柑"] = "柑",
        ["葡萄"] = "葡萄",
        ["西瓜"] = "西瓜",
        ["草莓"] = "草莓",
        ["芒果"] = "芒果",
        ["木瓜"] = "木瓜",
        ["鳳梨"] = "鳳梨",
        ["蓮霧"] = "蓮霧",
        ["龍眼"] = "龍眼",
        ["荔枝"] = "荔枝",
        ["釋迦"] = "釋迦",
        ["火龍果"] = "火龍果",
        ["百香果"] = "百香果",
        ["檸檬"] = "檸檬",
    };

    private static readonly Dictionary<string, List<string>> OfficialToAliases;

    static CropAliases()
    {
        OfficialToAliases = new Dictionary<string, List<string>>();
        foreach (var (alias, official) in AliasToOfficial)
        {
            if (!OfficialToAliases.ContainsKey(official))
                OfficialToAliases[official] = new List<string>();
            if (!OfficialToAliases[official].Contains(alias))
                OfficialToAliases[official].Add(alias);
        }
    }

    /// <summary>
    /// 由別名取得官方名稱（若無則回傳 null）
    /// </summary>
    public static string? FindOfficialName(string alias)
    {
        if (string.IsNullOrWhiteSpace(alias))
            return null;
        
        return AliasToOfficial.TryGetValue(alias.Trim(), out var official) ? official : null;
    }

    /// <summary>
    /// 取得官方名稱對應的所有別名（包括官方名稱本身）
    /// </summary>
    public static List<string> GetAllNames(string officialName)
    {
        if (string.IsNullOrWhiteSpace(officialName))
            return new List<string>();

        var result = new List<string> { officialName };
        if (OfficialToAliases.TryGetValue(officialName, out var aliases))
        {
            result.AddRange(aliases);
        }
        return result;
    }

    /// <summary>
    /// 取得特定作物的別名列表
    /// </summary>
    public static List<string> GetAliases(string cropName)
    {
        if (string.IsNullOrWhiteSpace(cropName))
            return new List<string>();

        var official = FindOfficialName(cropName) ?? cropName;
        var aliases = GetAllNames(official);
        
        // 移除官方名稱本身，只保留別名
        aliases.Remove(official);
        return aliases;
    }
}
