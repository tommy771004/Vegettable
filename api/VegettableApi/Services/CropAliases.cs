namespace VegettableApi.Services;

/// <summary>
/// 蔬果品項別名對照表
/// </summary>
public static class CropAliases
{
    private static readonly Dictionary<string, List<string>> Aliases = new()
    {
        // 根莖類
        ["甘薯"] = ["地瓜", "番薯", "蕃薯"],
        ["馬鈴薯"] = ["洋芋", "土豆"],
        ["蘿蔔"] = ["白蘿蔔", "菜頭"],
        ["胡蘿蔔"] = ["紅蘿蔔"],
        ["竹筍"] = ["筍子"],
        ["洋蔥"] = ["蔥頭"],
        ["大蒜"] = ["蒜頭", "蒜仁"],
        ["薑"] = ["老薑", "嫩薑", "生薑"],
        ["芋頭"] = ["芋仔"],
        ["蓮藕"] = ["藕"],
        ["牛蒡"] = ["牛蒡根"],

        // 葉菜類
        ["甘藍"] = ["高麗菜", "包心菜", "捲心菜", "圓白菜"],
        ["小白菜"] = ["青菜", "不結球白菜"],
        ["白菜"] = ["大白菜", "包心白", "山東白菜"],
        ["青江菜"] = ["湯匙菜"],
        ["芹菜"] = ["西芹", "美國芹菜"],
        ["菠菜"] = ["菠薐菜", "波菜"],
        ["茼蒿"] = ["打某菜", "春菊"],
        ["莧菜"] = ["赤莧", "白莧"],
        ["萵苣"] = ["A菜", "大陸妹", "美生菜", "蘿美生菜"],
        ["蕹菜"] = ["空心菜", "通菜"],
        ["油菜"] = ["油菜心"],
        ["韭菜"] = ["韭菜花", "韭黃"],
        ["芥菜"] = ["芥藍", "格藍菜", "刈菜"],
        ["蕃薯葉"] = ["地瓜葉", "甘薯葉"],

        // 花果菜類
        ["花椰菜"] = ["白花菜", "菜花"],
        ["青花菜"] = ["綠花椰菜", "西蘭花"],
        ["番茄"] = ["蕃茄", "西紅柿"],
        ["茄子"] = ["茄"],
        ["甜椒"] = ["彩椒", "青椒", "大椒"],
        ["辣椒"] = ["小辣椒", "朝天椒"],
        ["胡瓜"] = ["小黃瓜", "花胡瓜"],
        ["絲瓜"] = ["菜瓜"],
        ["苦瓜"] = ["涼瓜", "山苦瓜"],
        ["冬瓜"] = ["東瓜"],
        ["南瓜"] = ["金瓜"],
        ["扁蒲"] = ["蒲瓜", "瓠瓜", "瓠子"],
        ["食用玉米"] = ["甜玉米", "水果玉米", "玉米"],
        ["毛豆"] = ["枝豆"],
        ["豌豆"] = ["荷蘭豆", "甜豆"],
        ["敏豆"] = ["四季豆", "菜豆"],

        // 菇菌類
        ["香菇"] = ["冬菇", "花菇"],
        ["洋菇"] = ["蘑菇", "口蘑"],
        ["金針菇"] = ["金菇"],
        ["杏鮑菇"] = ["杏仁菇"],
        ["秀珍菇"] = ["鳳尾菇"],
        ["木耳"] = ["黑木耳", "雲耳"],

        // 水果
        ["香蕉"] = ["芎蕉"],
        ["鳳梨"] = ["菠蘿", "旺來"],
        ["西瓜"] = ["大西瓜", "小玉西瓜"],
        ["木瓜"] = ["萬壽果"],
        ["芒果"] = ["檨仔"],
        ["荔枝"] = [],
        ["龍眼"] = ["桂圓"],
        ["番石榴"] = ["芭樂", "芭拉"],
        ["蓮霧"] = [],
        ["柳橙"] = ["柳丁", "香丁"],
        ["椪柑"] = ["桶柑", "橘子"],
        ["葡萄"] = ["巨峰葡萄"],
        ["梨"] = ["水梨", "高接梨", "新興梨"],
        ["棗"] = ["蜜棗", "紅棗"],
        ["釋迦"] = ["番荔枝"],
        ["百香果"] = ["西番蓮"],
        ["火龍果"] = ["紅龍果"],
        ["檸檬"] = ["萊姆"],
        ["酪梨"] = ["鱷梨"],
        ["草莓"] = ["莓"],

        // 肉品
        ["毛豬"] = ["豬", "豬肉"],
        ["白肉雞"] = ["肉雞", "白雞"],
        ["紅羽土雞"] = ["土雞", "紅羽雞"],
        ["雞蛋"] = ["蛋", "雞卵"],
    };

    /// <summary>反向索引：別名 → 正式名稱</summary>
    private static readonly Dictionary<string, string> ReverseMap;

    static CropAliases()
    {
        ReverseMap = new Dictionary<string, string>();
        foreach (var (official, aliasList) in Aliases)
        {
            foreach (var alias in aliasList)
            {
                ReverseMap.TryAdd(alias, official);
            }
        }
    }

    /// <summary>取得品項的別名列表</summary>
    public static List<string> GetAliases(string cropName)
        => Aliases.GetValueOrDefault(cropName) ?? new List<string>();

    /// <summary>由別名反查正式名稱</summary>
    public static string? FindOfficialName(string alias)
    {
        if (Aliases.ContainsKey(alias)) return alias;
        return ReverseMap.GetValueOrDefault(alias);
    }

    /// <summary>取得品項所有名稱 (含正式名稱)</summary>
    public static List<string> GetAllNames(string cropName)
    {
        var names = new List<string> { cropName };
        names.AddRange(GetAliases(cropName));
        return names;
    }
}
