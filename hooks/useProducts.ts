import { useState, useEffect, useCallback } from 'react';
import { ProductSummary, CropCategory } from '@/types';
import { fetchRecentProducts, searchProducts } from '@/services/api';
import { useFavorites } from './useFavorites';

export function useProducts() {
  const [products, setProducts] = useState<ProductSummary[]>([]);
  const [filteredProducts, setFilteredProducts] = useState<ProductSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchKeyword, setSearchKeyword] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<CropCategory | 'all'>('all');
  const { favorites } = useFavorites();

  const loadProducts = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchRecentProducts();
      setProducts(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : '載入失敗，請稍後再試');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadProducts();
  }, [loadProducts]);

  // 根據搜尋和篩選更新列表
  useEffect(() => {
    let result = products;

    // 類別篩選
    if (selectedCategory !== 'all') {
      result = result.filter((p) => p.category === selectedCategory);
    }

    // 關鍵字搜尋
    if (searchKeyword.trim()) {
      result = searchProducts(result, searchKeyword);
    }

    // 收藏優先排序
    result = [...result].sort((a, b) => {
      const aFav = favorites.includes(a.cropCode) ? -1 : 0;
      const bFav = favorites.includes(b.cropCode) ? -1 : 0;
      if (aFav !== bFav) return aFav - bFav;
      // 再按價格等級排序（便宜的在前）
      const levelOrder = { 'very-cheap': 0, 'cheap': 1, 'normal': 2, 'expensive': 3 };
      return levelOrder[a.priceLevel] - levelOrder[b.priceLevel];
    });

    setFilteredProducts(result);
  }, [products, searchKeyword, selectedCategory, favorites]);

  return {
    products: filteredProducts,
    allProducts: products,
    loading,
    error,
    searchKeyword,
    setSearchKeyword,
    selectedCategory,
    setSelectedCategory,
    refresh: loadProducts,
  };
}
