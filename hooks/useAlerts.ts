import { useState, useEffect, useCallback } from 'react';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { PriceAlert } from '@/types';
import { fetchAlerts, createAlert, deleteAlert, toggleAlert } from '@/services/api';

const DEVICE_TOKEN_KEY = '@vegettable_push_token';

export function useAlerts() {
  const [alerts, setAlerts] = useState<PriceAlert[]>([]);
  const [deviceToken, setDeviceToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // 初始化 push token
  useEffect(() => {
    initPushToken();
  }, []);

  // 載入警示
  useEffect(() => {
    if (deviceToken) loadAlerts();
  }, [deviceToken]);

  const initPushToken = async () => {
    try {
      // 先檢查是否已存過 token
      const stored = await AsyncStorage.getItem(DEVICE_TOKEN_KEY);
      if (stored) {
        setDeviceToken(stored);
        return;
      }

      // 嘗試向 Expo 取得 Push Token
      if (Platform.OS === 'web') {
        // Web 不支援 push，使用隨機 ID
        const webId = `web-${Date.now()}-${Math.random().toString(36).slice(2)}`;
        await AsyncStorage.setItem(DEVICE_TOKEN_KEY, webId);
        setDeviceToken(webId);
        return;
      }

      // 動態 import expo-notifications (避免 web 報錯)
      try {
        const Notifications = require('expo-notifications');
        const { status } = await Notifications.requestPermissionsAsync();
        if (status === 'granted') {
          const token = await Notifications.getExpoPushTokenAsync();
          await AsyncStorage.setItem(DEVICE_TOKEN_KEY, token.data);
          setDeviceToken(token.data);
        }
      } catch {
        // expo-notifications 未安裝，使用 fallback ID
        const fallbackId = `device-${Date.now()}`;
        await AsyncStorage.setItem(DEVICE_TOKEN_KEY, fallbackId);
        setDeviceToken(fallbackId);
      }
    } catch {
      // ignore
    }
  };

  const loadAlerts = useCallback(async () => {
    if (!deviceToken) return;
    setLoading(true);
    try {
      const data = await fetchAlerts(deviceToken);
      setAlerts(data);
    } catch {
      // 靜默失敗
    } finally {
      setLoading(false);
    }
  }, [deviceToken]);

  const addAlert = useCallback(async (
    cropName: string,
    targetPrice: number,
    condition: 'below' | 'above' = 'below'
  ) => {
    if (!deviceToken) return;
    try {
      const alert = await createAlert({ deviceToken, cropName, targetPrice, condition });
      setAlerts(prev => [alert, ...prev]);
    } catch {
      throw new Error('建立警示失敗');
    }
  }, [deviceToken]);

  const removeAlert = useCallback(async (id: number) => {
    if (!deviceToken) return;
    try {
      await deleteAlert(id, deviceToken);
      setAlerts(prev => prev.filter(a => a.id !== id));
    } catch {
      // ignore
    }
  }, [deviceToken]);

  const toggleAlertActive = useCallback(async (id: number) => {
    if (!deviceToken) return;
    try {
      await toggleAlert(id, deviceToken);
      setAlerts(prev => prev.map(a =>
        a.id === id ? { ...a, isActive: !a.isActive } : a
      ));
    } catch {
      // ignore
    }
  }, [deviceToken]);

  return {
    alerts,
    loading,
    deviceToken,
    addAlert,
    removeAlert,
    toggleAlertActive,
    refreshAlerts: loadAlerts,
  };
}
