/**
 * 日期工具 — 處理民國年 (ROC) 與西元年轉換
 * 農委會 API 使用民國年格式：YYY.MM.DD
 */

/** 西元年轉民國年 */
export function toROCDate(date: Date): string {
  const year = date.getFullYear() - 1911;
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}.${month}.${day}`;
}

/** 民國年轉西元 Date */
export function fromROCDate(rocDate: string): Date {
  const parts = rocDate.replace(/\//g, '.').split('.');
  const year = parseInt(parts[0], 10) + 1911;
  const month = parseInt(parts[1], 10) - 1;
  const day = parseInt(parts[2], 10);
  return new Date(year, month, day);
}

/** 取得 N 天前的日期 */
export function daysAgo(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

/** 取得 N 年前的日期 */
export function yearsAgo(n: number): Date {
  const d = new Date();
  d.setFullYear(d.getFullYear() - n);
  return d;
}

/** 格式化日期為 MM/DD */
export function formatShortDate(dateStr: string): string {
  const date = fromROCDate(dateStr);
  return `${date.getMonth() + 1}/${date.getDate()}`;
}

/** 格式化日期為 YYYY/MM */
export function formatYearMonth(dateStr: string): string {
  const date = fromROCDate(dateStr);
  return `${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, '0')}`;
}

/** 取得今天的民國年日期 */
export function todayROC(): string {
  return toROCDate(new Date());
}
