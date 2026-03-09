#!/usr/bin/env python3
"""
App Icon PNG 生成器 — 使用純 Python 生成綠色漸層 + 折線圖指數風格圖示
無需外部依賴 (不需 Pillow)
"""
import struct
import zlib
import os
import math

def create_png(width, height, pixels):
    """生成 PNG 檔案的 bytes"""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xffffffff)
        return struct.pack('>I', len(data)) + c + crc

    # PNG signature
    sig = b'\x89PNG\r\n\x1a\n'

    # IHDR
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)  # 8-bit RGB

    # IDAT — raw pixel data with filter bytes
    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter: none
        for x in range(width):
            idx = (y * width + x) * 3
            raw += bytes(pixels[idx:idx+3])

    compressed = zlib.compress(raw, 9)

    return sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', compressed) + chunk(b'IEND', b'')


def lerp(a, b, t):
    return int(a + (b - a) * t)


def color_lerp(c1, c2, t):
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))


def generate_icon(size):
    """生成指定大小的圖示像素資料"""
    pixels = [0] * (size * size * 3)

    # 顏色定義
    green_top = (67, 160, 71)      # #43A047
    green_mid = (46, 125, 50)      # #2E7D32
    green_dark = (27, 94, 32)      # #1B5E20
    white = (255, 255, 255)
    light_green = (165, 214, 167)  # #A5D6A7

    # 圓角半徑
    corner_r = size * 224 // 1024

    # 圖表折線點 (歸一化到 0-1)
    chart_points = [
        (0.156, 0.732), (0.254, 0.664), (0.352, 0.684),
        (0.449, 0.566), (0.547, 0.508), (0.645, 0.391),
        (0.742, 0.342), (0.840, 0.273),
    ]

    def in_rounded_rect(x, y):
        """檢查點是否在圓角矩形內"""
        if x < corner_r:
            if y < corner_r:
                dx, dy = corner_r - x, corner_r - y
                return dx*dx + dy*dy <= corner_r*corner_r
            elif y > size - corner_r:
                dx, dy = corner_r - x, y - (size - corner_r)
                return dx*dx + dy*dy <= corner_r*corner_r
        elif x > size - corner_r:
            if y < corner_r:
                dx, dy = x - (size - corner_r), corner_r - y
                return dx*dx + dy*dy <= corner_r*corner_r
            elif y > size - corner_r:
                dx, dy = x - (size - corner_r), y - (size - corner_r)
                return dx*dx + dy*dy <= corner_r*corner_r
        return 0 <= x < size and 0 <= y < size

    def get_chart_y(nx):
        """根據 x 位置插值取得圖表 y"""
        for i in range(len(chart_points) - 1):
            x1, y1 = chart_points[i]
            x2, y2 = chart_points[i + 1]
            if x1 <= nx <= x2:
                t = (nx - x1) / (x2 - x1) if x2 != x1 else 0
                return y1 + (y2 - y1) * t
        return chart_points[-1][1]

    def dist_to_line_segment(px, py, x1, y1, x2, y2):
        """點到線段的距離"""
        dx, dy = x2 - x1, y2 - y1
        if dx == 0 and dy == 0:
            return math.sqrt((px-x1)**2 + (py-y1)**2)
        t = max(0, min(1, ((px-x1)*dx + (py-y1)*dy) / (dx*dx + dy*dy)))
        proj_x = x1 + t * dx
        proj_y = y1 + t * dy
        return math.sqrt((px - proj_x)**2 + (py - proj_y)**2)

    line_width = max(2, size * 14 // 1024)
    point_r = max(2, size * 12 // 1024)

    for y in range(size):
        for x in range(size):
            if not in_rounded_rect(x, y):
                idx = (y * size + x) * 3
                pixels[idx] = pixels[idx+1] = pixels[idx+2] = 0
                continue

            nx = x / size
            ny = y / size

            # 背景漸層 (左上 → 右下)
            t = (nx + ny) / 2
            if t < 0.5:
                bg = color_lerp(green_top, green_mid, t * 2)
            else:
                bg = color_lerp(green_mid, green_dark, (t - 0.5) * 2)

            r, g, b = bg

            # 裝飾性光暈
            dx1 = (nx - 0.27)
            dy1 = (ny - 0.27)
            dist1 = math.sqrt(dx1*dx1 + dy1*dy1)
            if dist1 < 0.3:
                alpha = 0.04 * (1 - dist1 / 0.3)
                r = lerp(r, 255, alpha)
                g = lerp(g, 255, alpha)
                b = lerp(b, 255, alpha)

            # 圖表面積填充
            chart_start_x = 0.156
            chart_end_x = 0.840
            chart_bottom = 0.732

            if chart_start_x <= nx <= chart_end_x:
                chart_y = get_chart_y(nx)
                if chart_y <= ny <= chart_bottom:
                    fill_t = (ny - chart_y) / (chart_bottom - chart_y) if chart_bottom != chart_y else 1
                    alpha = 0.35 * (1 - fill_t)
                    r = lerp(r, light_green[0], alpha)
                    g = lerp(g, light_green[1], alpha)
                    b = lerp(b, light_green[2], alpha)

            # 折線
            min_dist = float('inf')
            for i in range(len(chart_points) - 1):
                x1p, y1p = chart_points[i]
                x2p, y2p = chart_points[i + 1]
                d = dist_to_line_segment(nx, ny, x1p, y1p, x2p, y2p)
                min_dist = min(min_dist, d)

            line_w_norm = line_width / size
            if min_dist < line_w_norm:
                alpha = max(0, 1 - min_dist / line_w_norm)
                r = lerp(r, light_green[0], alpha * 0.9)
                g = lerp(g, light_green[1], alpha * 0.9)
                b = lerp(b, light_green[2], alpha * 0.9)

            # 數據點
            for px, py in chart_points:
                dx = (nx - px) * size
                dy = (ny - py) * size
                dist = math.sqrt(dx*dx + dy*dy)
                if dist < point_r:
                    alpha = max(0, 1 - dist / point_r)
                    r = lerp(r, 232, alpha * 0.85)
                    g = lerp(g, 245, alpha * 0.85)
                    b = lerp(b, 233, alpha * 0.85)

            # 最後一個點 (白色高亮)
            last_x, last_y = chart_points[-1]
            dx = (nx - last_x) * size
            dy = (ny - last_y) * size
            dist = math.sqrt(dx*dx + dy*dy)
            big_r = point_r * 1.3
            if dist < big_r:
                alpha = max(0, 1 - dist / big_r)
                r = lerp(r, 255, alpha * 0.95)
                g = lerp(g, 255, alpha * 0.95)
                b = lerp(b, 255, alpha * 0.95)

            # 向上箭頭
            arrow_cx = 0.84
            arrow_cy = 0.18
            arrow_w = 0.06
            arrow_h = 0.09
            ax = nx - arrow_cx
            ay = ny - arrow_cy

            # 三角形頂部
            tri_top = -arrow_h * 0.5
            tri_bottom = -arrow_h * 0.1
            if tri_top <= ay <= tri_bottom:
                tri_t = (ay - tri_top) / (tri_bottom - tri_top) if tri_bottom != tri_top else 0
                half_w = arrow_w * 0.5 * tri_t
                if -half_w <= ax <= half_w:
                    r = lerp(r, 255, 0.85)
                    g = lerp(g, 255, 0.85)
                    b = lerp(b, 255, 0.85)

            # 矩形柱體
            stem_w = arrow_w * 0.3
            if tri_bottom <= ay <= arrow_h * 0.5 and -stem_w <= ax <= stem_w:
                r = lerp(r, 255, 0.85)
                g = lerp(g, 255, 0.85)
                b = lerp(b, 255, 0.85)

            # 葉子圖示 (左上角)
            leaf_cx = 0.17
            leaf_cy = 0.22
            leaf_dx = (nx - leaf_cx)
            leaf_dy = (ny - leaf_cy)
            leaf_dist = math.sqrt(leaf_dx*leaf_dx + leaf_dy*leaf_dy)
            if leaf_dist < 0.08:
                # 簡單橢圓葉子
                ex = leaf_dx / 0.05
                ey = leaf_dy / 0.08
                if ex*ex + ey*ey < 1:
                    r = lerp(r, 255, 0.8)
                    g = lerp(g, 255, 0.8)
                    b = lerp(b, 255, 0.8)

            r = max(0, min(255, r))
            g = max(0, min(255, g))
            b = max(0, min(255, b))

            idx = (y * size + x) * 3
            pixels[idx] = r
            pixels[idx+1] = g
            pixels[idx+2] = b

    return pixels


# 生成各種大小
sizes = {
    # iOS
    'AppIcon-1024.png': 1024,
    'AppIcon-180.png': 180,   # iPhone @3x
    'AppIcon-120.png': 120,   # iPhone @2x
    'AppIcon-167.png': 167,   # iPad Pro @2x
    'AppIcon-152.png': 152,   # iPad @2x
    # Android
    'ic_launcher-xxxhdpi.png': 192,
    'ic_launcher-xxhdpi.png': 144,
    'ic_launcher-xhdpi.png': 96,
    'ic_launcher-hdpi.png': 72,
    'ic_launcher-mdpi.png': 48,
}

output_dir = os.path.dirname(os.path.abspath(__file__))

for filename, size in sizes.items():
    print(f'正在生成 {filename} ({size}x{size})...')
    pixels = generate_icon(size)
    png_data = create_png(size, size, pixels)
    filepath = os.path.join(output_dir, filename)
    with open(filepath, 'wb') as f:
        f.write(png_data)
    print(f'  完成: {filepath}')

print('\n全部圖示生成完畢！')
