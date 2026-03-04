import React, { useState } from 'react';
import {
  View, Text, StyleSheet, FlatList, TouchableOpacity,
  TextInput, Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { BlurView } from 'expo-blur';
import { GlassCard } from './GlassCard';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';
import { PriceAlert, ProductSummary } from '@/types';

interface Props {
  alerts: PriceAlert[];
  products: ProductSummary[];
  onAddAlert: (cropName: string, targetPrice: number, condition: 'below' | 'above') => void;
  onDeleteAlert: (id: number) => void;
  onToggleAlert: (id: number) => void;
}

export function AlertManager({ alerts, products, onAddAlert, onDeleteAlert, onToggleAlert }: Props) {
  const [showModal, setShowModal] = useState(false);
  const [selectedCrop, setSelectedCrop] = useState('');
  const [targetPrice, setTargetPrice] = useState('');
  const [condition, setCondition] = useState<'below' | 'above'>('below');

  const handleAdd = () => {
    const price = parseFloat(targetPrice);
    if (!selectedCrop || isNaN(price) || price <= 0) return;
    onAddAlert(selectedCrop, price, condition);
    setShowModal(false);
    setSelectedCrop('');
    setTargetPrice('');
  };

  return (
    <View style={styles.container}>
      <View style={styles.headerRow}>
        <Text style={styles.title}>價格警示</Text>
        <TouchableOpacity onPress={() => setShowModal(true)} style={styles.addButton}>
          <Ionicons name="add-circle" size={24} color={Colors.primary} />
        </TouchableOpacity>
      </View>

      {alerts.length === 0 ? (
        <GlassCard style={styles.emptyCard}>
          <Ionicons name="notifications-off-outline" size={32} color={Colors.textTertiary} />
          <Text style={styles.emptyText}>尚未設定任何警示</Text>
          <Text style={styles.emptySubtext}>設定警示後，當價格達到目標時會通知您</Text>
        </GlassCard>
      ) : (
        <FlatList
          data={alerts}
          keyExtractor={item => String(item.id)}
          scrollEnabled={false}
          renderItem={({ item }) => (
            <GlassCard style={styles.alertCard}>
              <View style={styles.alertRow}>
                <TouchableOpacity onPress={() => onToggleAlert(item.id)}>
                  <Ionicons
                    name={item.isActive ? 'notifications' : 'notifications-off'}
                    size={20}
                    color={item.isActive ? Colors.primary : Colors.textTertiary}
                  />
                </TouchableOpacity>
                <View style={styles.alertInfo}>
                  <Text style={styles.alertCrop}>{item.cropName}</Text>
                  <Text style={styles.alertCondition}>
                    {item.condition === 'below' ? '低於' : '高於'} ${item.targetPrice}/kg
                  </Text>
                </View>
                <TouchableOpacity onPress={() => onDeleteAlert(item.id)}>
                  <Ionicons name="trash-outline" size={18} color={Colors.trend.up} />
                </TouchableOpacity>
              </View>
            </GlassCard>
          )}
        />
      )}

      {/* 新增警示 Modal */}
      <Modal visible={showModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <BlurView intensity={80} tint="light" style={styles.modalContent}>
            <Text style={styles.modalTitle}>新增價格警示</Text>

            <Text style={styles.modalLabel}>選擇品項</Text>
            <FlatList
              data={products.slice(0, 15)}
              horizontal
              showsHorizontalScrollIndicator={false}
              keyExtractor={p => p.cropCode}
              style={styles.cropList}
              renderItem={({ item }) => (
                <TouchableOpacity
                  onPress={() => setSelectedCrop(item.cropName)}
                  style={[styles.cropChip, selectedCrop === item.cropName && styles.cropChipActive]}
                >
                  <Text style={[
                    styles.cropChipText,
                    selectedCrop === item.cropName && styles.cropChipTextActive,
                  ]}>
                    {item.cropName} ${item.avgPrice}
                  </Text>
                </TouchableOpacity>
              )}
            />

            <Text style={styles.modalLabel}>條件</Text>
            <View style={styles.conditionRow}>
              {(['below', 'above'] as const).map(c => (
                <TouchableOpacity
                  key={c}
                  onPress={() => setCondition(c)}
                  style={[styles.conditionBtn, condition === c && styles.conditionBtnActive]}
                >
                  <Text style={[styles.conditionText, condition === c && styles.conditionTextActive]}>
                    {c === 'below' ? '低於' : '高於'}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Text style={styles.modalLabel}>目標價格 (元/公斤)</Text>
            <TextInput
              style={styles.priceInput}
              value={targetPrice}
              onChangeText={setTargetPrice}
              keyboardType="numeric"
              placeholder="例如: 15"
              placeholderTextColor={Colors.textTertiary}
            />

            <View style={styles.modalActions}>
              <TouchableOpacity onPress={() => setShowModal(false)} style={styles.cancelBtn}>
                <Text style={styles.cancelText}>取消</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={handleAdd} style={styles.confirmBtn}>
                <Text style={styles.confirmText}>建立</Text>
              </TouchableOpacity>
            </View>
          </BlurView>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { marginTop: Spacing.md },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: Spacing.sm },
  title: { fontSize: FontSize.lg, fontWeight: '600', color: Colors.text },
  addButton: { padding: 4 },
  emptyCard: {
    marginHorizontal: 0,
    alignItems: 'center',
    gap: Spacing.sm,
    paddingVertical: Spacing.xxl,
  },
  emptyText: { fontSize: FontSize.md, color: Colors.textSecondary, fontWeight: '600' },
  emptySubtext: { fontSize: FontSize.sm, color: Colors.textTertiary },
  alertCard: { marginHorizontal: 0, marginBottom: Spacing.xs },
  alertRow: { flexDirection: 'row', alignItems: 'center', gap: Spacing.md },
  alertInfo: { flex: 1 },
  alertCrop: { fontSize: FontSize.md, fontWeight: '600', color: Colors.text },
  alertCondition: { fontSize: FontSize.sm, color: Colors.textSecondary, marginTop: 2 },
  modalOverlay: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  modalContent: {
    borderTopLeftRadius: BorderRadius.xxl,
    borderTopRightRadius: BorderRadius.xxl,
    padding: Spacing.xxl,
    overflow: 'hidden',
  },
  modalTitle: { fontSize: FontSize.xl, fontWeight: '700', color: Colors.text, marginBottom: Spacing.lg },
  modalLabel: { fontSize: FontSize.sm, color: Colors.textSecondary, fontWeight: '600', marginTop: Spacing.md, marginBottom: Spacing.xs },
  cropList: { maxHeight: 44 },
  cropChip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    borderRadius: BorderRadius.pill,
    backgroundColor: Colors.glass.background,
    borderWidth: 0.5,
    borderColor: Colors.glass.border,
    marginRight: Spacing.xs,
  },
  cropChipActive: { borderColor: Colors.primary, backgroundColor: Colors.primarySurface },
  cropChipText: { fontSize: FontSize.sm, color: Colors.textSecondary },
  cropChipTextActive: { color: Colors.primary, fontWeight: '600' },
  conditionRow: { flexDirection: 'row', gap: Spacing.sm },
  conditionBtn: {
    flex: 1,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.md,
    backgroundColor: Colors.glass.background,
    alignItems: 'center',
    borderWidth: 0.5,
    borderColor: Colors.glass.border,
  },
  conditionBtnActive: { borderColor: Colors.primary, backgroundColor: Colors.primarySurface },
  conditionText: { fontSize: FontSize.md, color: Colors.textSecondary },
  conditionTextActive: { color: Colors.primary, fontWeight: '600' },
  priceInput: {
    borderWidth: 1,
    borderColor: Colors.glass.border,
    borderRadius: BorderRadius.md,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    fontSize: FontSize.lg,
    color: Colors.text,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: Spacing.md,
    marginTop: Spacing.xxl,
  },
  cancelBtn: { paddingVertical: Spacing.md, paddingHorizontal: Spacing.xxl },
  cancelText: { fontSize: FontSize.md, color: Colors.textSecondary },
  confirmBtn: {
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.xxl,
    backgroundColor: Colors.primary,
    borderRadius: BorderRadius.md,
  },
  confirmText: { fontSize: FontSize.md, color: Colors.white, fontWeight: '600' },
});
