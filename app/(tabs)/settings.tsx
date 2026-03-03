import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Switch,
  TouchableOpacity,
  ScrollView,
  Linking,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { GlassHeader } from '@/components/GlassHeader';
import { GlassCard } from '@/components/GlassCard';
import { useSettings } from '@/hooks/useSettings';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

export default function SettingsScreen() {
  const { settings, togglePriceUnit, toggleRetailPrice } = useSettings();

  return (
    <LinearGradient
      colors={[Colors.backgroundGradientStart, Colors.backgroundGradientEnd]}
      style={styles.container}
    >
      <GlassHeader title="設定" />

      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* 價格設定 */}
        <Text style={styles.sectionTitle}>價格顯示</Text>
        <GlassCard style={styles.card}>
          <View style={styles.settingRow}>
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>價格單位</Text>
              <Text style={styles.settingDesc}>
                {settings.priceUnit === 'kg' ? '公斤 (原始批發單位)' : '台斤 (1台斤 = 0.6公斤)'}
              </Text>
            </View>
            <TouchableOpacity onPress={togglePriceUnit} style={styles.toggleButton}>
              <Text style={styles.toggleText}>
                {settings.priceUnit === 'kg' ? '公斤' : '台斤'}
              </Text>
              <Ionicons name="swap-horizontal" size={16} color={Colors.primary} />
            </TouchableOpacity>
          </View>

          <View style={styles.divider} />

          <View style={styles.settingRow}>
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>顯示零售參考價</Text>
              <Text style={styles.settingDesc}>
                以批發價 × 2.5 粗估零售價
              </Text>
            </View>
            <Switch
              value={settings.showRetailPrice}
              onValueChange={toggleRetailPrice}
              trackColor={{ false: '#E0E0E0', true: Colors.primaryLight + '60' }}
              thumbColor={settings.showRetailPrice ? Colors.primary : '#FAFAFA'}
            />
          </View>
        </GlassCard>

        {/* 價格等級說明 */}
        <Text style={styles.sectionTitle}>價格等級說明</Text>
        <GlassCard style={styles.card}>
          <View style={styles.levelRow}>
            <View style={[styles.levelDot, { backgroundColor: Colors.priceLevel['very-cheap'] }]} />
            <View style={styles.levelInfo}>
              <Text style={styles.levelLabel}>當令便宜</Text>
              <Text style={styles.levelDesc}>目前均價低於歷史均價 30% 以上</Text>
            </View>
          </View>
          <View style={styles.levelRow}>
            <View style={[styles.levelDot, { backgroundColor: Colors.priceLevel['cheap'] }]} />
            <View style={styles.levelInfo}>
              <Text style={styles.levelLabel}>相對便宜</Text>
              <Text style={styles.levelDesc}>目前均價低於歷史均價 10~30%</Text>
            </View>
          </View>
          <View style={styles.levelRow}>
            <View style={[styles.levelDot, { backgroundColor: Colors.priceLevel['normal'] }]} />
            <View style={styles.levelInfo}>
              <Text style={styles.levelLabel}>略偏貴</Text>
              <Text style={styles.levelDesc}>目前均價接近或略高於歷史均價</Text>
            </View>
          </View>
          <View style={styles.levelRow}>
            <View style={[styles.levelDot, { backgroundColor: Colors.priceLevel['expensive'] }]} />
            <View style={styles.levelInfo}>
              <Text style={styles.levelLabel}>相對偏貴</Text>
              <Text style={styles.levelDesc}>目前均價高於歷史均價 15% 以上</Text>
            </View>
          </View>
        </GlassCard>

        {/* 關於 */}
        <Text style={styles.sectionTitle}>關於</Text>
        <GlassCard style={styles.card}>
          <Text style={styles.aboutText}>
            「當令蔬果生鮮」幫你收集農業部提供的每日農產品、漁產品、家禽交易行情資料，
            將全台近期一週的批發均價與近三年資料比較，讓你在市場買菜時快速判斷是否為當令好價格。
          </Text>
          <View style={styles.divider} />
          <Text style={styles.disclaimer}>
            注意：價格為全台所有批發市場的產量加權平均，加上各市場管銷通路等因素不同，
            此處批發價或零售估價僅供趨勢參考，不代表實際售價。
          </Text>
          <View style={styles.divider} />
          <TouchableOpacity
            style={styles.linkRow}
            onPress={() => Linking.openURL('https://data.moa.gov.tw/')}
          >
            <Ionicons name="globe-outline" size={18} color={Colors.primary} />
            <Text style={styles.linkText}>資料來源：農業資料開放平臺</Text>
            <Ionicons name="open-outline" size={14} color={Colors.textTertiary} />
          </TouchableOpacity>
        </GlassCard>

        <View style={styles.footer}>
          <Text style={styles.footerText}>當令蔬果生鮮 v1.0.0</Text>
          <Text style={styles.footerText}>資料來源：農業部 · 農糧署</Text>
        </View>
      </ScrollView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: Spacing.lg,
    paddingBottom: 120,
  },
  sectionTitle: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    color: Colors.textTertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginTop: Spacing.xl,
    marginBottom: Spacing.sm,
    marginLeft: Spacing.xs,
  },
  card: {
    marginHorizontal: 0,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  settingInfo: {
    flex: 1,
    marginRight: Spacing.md,
  },
  settingLabel: {
    fontSize: FontSize.md,
    fontWeight: '600',
    color: Colors.text,
  },
  settingDesc: {
    fontSize: FontSize.sm,
    color: Colors.textTertiary,
    marginTop: 2,
  },
  toggleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
    backgroundColor: Colors.primarySurface,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.pill,
  },
  toggleText: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    color: Colors.primary,
  },
  divider: {
    height: 0.5,
    backgroundColor: Colors.divider,
    marginVertical: Spacing.md,
  },
  levelRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    paddingVertical: Spacing.xs,
  },
  levelDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  levelInfo: {
    flex: 1,
  },
  levelLabel: {
    fontSize: FontSize.md,
    fontWeight: '600',
    color: Colors.text,
  },
  levelDesc: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
    marginTop: 1,
  },
  aboutText: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    lineHeight: 22,
  },
  disclaimer: {
    fontSize: FontSize.sm,
    color: Colors.textTertiary,
    lineHeight: 20,
  },
  linkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  linkText: {
    fontSize: FontSize.md,
    color: Colors.primary,
    fontWeight: '500',
    flex: 1,
  },
  footer: {
    alignItems: 'center',
    marginTop: Spacing.xxxl,
    gap: Spacing.xs,
  },
  footerText: {
    fontSize: FontSize.xs,
    color: Colors.textTertiary,
  },
});
