import { CropCategory, VegetableSubCategory } from '@/types';

export interface CategoryInfo {
  key: CropCategory;
  label: string;
  icon: string;
  color: string;
}

export interface VegetableSubCategoryInfo {
  key: VegetableSubCategory;
  label: string;
  icon: string;
}

export const CATEGORIES: CategoryInfo[] = [
  { key: 'vegetable', label: '蔬菜', icon: 'leaf', color: '#4CAF50' },
  { key: 'fruit', label: '水果', icon: 'nutrition', color: '#FF9800' },
  { key: 'fish', label: '漁產', icon: 'fish', color: '#2196F3' },
  { key: 'meat', label: '肉品', icon: 'restaurant', color: '#F44336' },
  { key: 'flower', label: '花卉', icon: 'flower', color: '#E91E63' },
  { key: 'rice', label: '白米', icon: 'grid', color: '#795548' },
];

export const VEGETABLE_SUB_CATEGORIES: VegetableSubCategoryInfo[] = [
  { key: 'root', label: '根莖類', icon: 'ellipse' },
  { key: 'leafy', label: '葉菜類', icon: 'leaf' },
  { key: 'flower', label: '花果菜類', icon: 'flower' },
  { key: 'mushroom', label: '菇菌類', icon: 'cloudy' },
  { key: 'pickled', label: '醃漬類', icon: 'flask' },
];

/** 蔬菜類別代碼對照（作物代號前綴分類） */
export const VEGETABLE_CODE_CATEGORY: Record<string, VegetableSubCategory> = {
  // 根莖類
  'LA1': 'root', // 甘薯
  'SA1': 'root', // 馬鈴薯
  'LA3': 'root', // 蘿蔔
  'LA4': 'root', // 胡蘿蔔
  'LA5': 'root', // 竹筍
  'SB1': 'root', // 洋蔥
  'LA6': 'root', // 牛蒡
  'SB2': 'root', // 大蒜
  'LA7': 'root', // 薑
  'SB3': 'root', // 蓮藕
  'LA8': 'root', // 芋頭
  'SD1': 'root', // 洋蔥
  // 葉菜類
  'LC1': 'leafy', // 甘藍
  'SC1': 'leafy', // 小白菜
  'LC2': 'leafy', // 白菜
  'SC2': 'leafy', // 青江菜
  'LC3': 'leafy', // 芹菜
  'LC4': 'leafy', // 菠菜
  'LC5': 'leafy', // 茼蒿
  'LC6': 'leafy', // 莧菜
  'SC3': 'leafy', // 萵苣
  'LC7': 'leafy', // 蕹菜(空心菜)
  'SC4': 'leafy', // 油菜
  'LC8': 'leafy', // 韭菜
  'SC5': 'leafy', // 芥菜
  'SC6': 'leafy', // 蕃薯葉
  // 花果菜類
  'LE1': 'flower', // 花椰菜
  'SE1': 'flower', // 胡瓜
  'LE2': 'flower', // 大蒜苗
  'SE2': 'flower', // 絲瓜
  'LE3': 'flower', // 番茄
  'SE3': 'flower', // 苦瓜
  'LE4': 'flower', // 茄子
  'SE4': 'flower', // 冬瓜
  'LE5': 'flower', // 甜椒
  'SE5': 'flower', // 南瓜
  'LE6': 'flower', // 辣椒
  'SE6': 'flower', // 扁蒲
  'LE7': 'flower', // 毛豆
  'SE7': 'flower', // 隼人瓜
  'SE8': 'flower', // 食用玉米
  'SF1': 'flower', // 豌豆
  'SF2': 'flower', // 敏豆
  // 菇菌類
  'SG1': 'mushroom', // 香菇
  'SG2': 'mushroom', // 洋菇
  'SG3': 'mushroom', // 金針菇
  'SG4': 'mushroom', // 杏鮑菇
  'SG5': 'mushroom', // 秀珍菇
  'SG6': 'mushroom', // 木耳
  // 醃漬類
  'SH1': 'pickled', // 酸菜
  'SH2': 'pickled', // 蘿蔔乾
  'SH3': 'pickled', // 筍乾
  'SH4': 'pickled', // 梅乾菜
};

/** 價格等級標籤 */
export const PRICE_LEVEL_LABELS: Record<string, string> = {
  'very-cheap': '當令便宜',
  'cheap': '相對便宜',
  'normal': '略偏貴',
  'expensive': '相對偏貴',
};
