#!/usr/bin/env python3
"""
XKAILive App Icon 生成脚本
使用 PIL (Pillow) 库生成 App Icon

安装依赖：
pip install Pillow

使用方法：
python generate_app_icon.py
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import os
except ImportError:
    print("❌ 需要安装 Pillow 库")
    print("请运行: pip install Pillow")
    exit(1)

def create_app_icon(size=1024):
    """创建 App Icon"""
    # 创建画布
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # 计算圆角半径（iOS 标准圆角）
    corner_radius = int(size * 0.215)
    
    # 绘制渐变背景 - 使用开直播卡片的渐变色
    # 从深紫色 -> 粉红色 -> 橙红色 -> 金黄色
    # 渐变方向：从左上角 (topLeading) 到右下角 (bottomTrailing)
    colors = [
        (128, 51, 230),   # 深紫色 (0.5, 0.2, 0.9)
        (230, 77, 153),   # 粉红色 (0.9, 0.3, 0.6)
        (255, 128, 77),   # 橙红色 (1.0, 0.5, 0.3)
        (255, 179, 51)    # 金黄色 (1.0, 0.7, 0.2)
    ]
    
    # 创建对角线渐变效果（从左上到右下）
    # 使用更高效的方法：计算对角线距离
    diagonal_length = (size ** 2 + size ** 2) ** 0.5
    
    # 使用行级渐变，提高效率
    for y in range(size):
        for x in range(size):
            # 计算从左上角 (0,0) 到当前点 (x,y) 的对角线距离比例
            # 使用曼哈顿距离的变体，更接近对角线效果
            distance = (x + y) / (size * 2)
            
            # 确定当前比例在哪个颜色区间
            if distance < 0.33:
                # 深紫色 -> 粉红色
                local_ratio = distance / 0.33
                color1 = colors[0]
                color2 = colors[1]
            elif distance < 0.66:
                # 粉红色 -> 橙红色
                local_ratio = (distance - 0.33) / 0.33
                color1 = colors[1]
                color2 = colors[2]
            else:
                # 橙红色 -> 金黄色
                local_ratio = (distance - 0.66) / 0.34
                color1 = colors[2]
                color2 = colors[3]
            
            # 插值计算当前颜色
            r = int(color1[0] + (color2[0] - color1[0]) * local_ratio)
            g = int(color1[1] + (color2[1] - color1[1]) * local_ratio)
            b = int(color1[2] + (color2[2] - color1[2]) * local_ratio)
            
            draw.point((x, y), fill=(r, g, b))
    
    # 绘制 "XKAILive" 文字在左下角（像素风格）
    _draw_text(draw, size, text="XKAILive")
    
    # 应用圆角（iOS 标准）
    # 创建一个带圆角的遮罩
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], corner_radius, fill=255)
    
    # 应用遮罩
    output = Image.new('RGB', (size, size), (255, 255, 255))
    output.paste(img, (0, 0))
    output.putalpha(mask)
    
    return output

def create_dark_app_icon(size=1024):
    """创建深色模式 App Icon（使用更深的背景色）"""
    # 创建画布
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # 计算圆角半径（iOS 标准圆角）
    corner_radius = int(size * 0.215)
    
    # 绘制渐变背景 - 使用更深的渐变色（适合深色模式）
    # 从深紫色 -> 深粉红色 -> 深橙红色 -> 深金黄色
    colors = [
        (64, 25, 115),    # 更深的紫色
        (115, 38, 77),    # 更深的粉红色
        (128, 64, 38),    # 更深的橙红色
        (128, 90, 25)     # 更深的金黄色
    ]
    
    # 创建对角线渐变效果（从左上到右下）
    diagonal_length = (size ** 2 + size ** 2) ** 0.5
    
    for y in range(size):
        for x in range(size):
            distance = (x + y) / (size * 2)
            
            if distance < 0.33:
                local_ratio = distance / 0.33
                color1 = colors[0]
                color2 = colors[1]
            elif distance < 0.66:
                local_ratio = (distance - 0.33) / 0.33
                color1 = colors[1]
                color2 = colors[2]
            else:
                local_ratio = (distance - 0.66) / 0.34
                color1 = colors[2]
                color2 = colors[3]
            
            r = int(color1[0] + (color2[0] - color1[0]) * local_ratio)
            g = int(color1[1] + (color2[1] - color1[1]) * local_ratio)
            b = int(color1[2] + (color2[2] - color1[2]) * local_ratio)
            
            draw.point((x, y), fill=(r, g, b))
    
    # 绘制文字（与普通版本相同）
    _draw_text(draw, size, text="XKAILive")
    
    # 应用圆角
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], corner_radius, fill=255)
    
    output = Image.new('RGB', (size, size), (255, 255, 255))
    output.paste(img, (0, 0))
    output.putalpha(mask)
    
    return output

def create_tinted_app_icon(size=1024):
    """创建着色模式 App Icon（单色版本，iOS 会自动着色）"""
    # 创建画布（白色背景，iOS 会自动着色）
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # 计算圆角半径（iOS 标准圆角）
    corner_radius = int(size * 0.215)
    
    # 绘制单色背景（浅灰色，iOS 会自动着色）
    # 使用浅灰色渐变，iOS 系统会根据用户设置自动着色
    colors = [
        (200, 200, 200),  # 浅灰色
        (180, 180, 180),  # 稍深的灰色
        (160, 160, 160),  # 更深的灰色
        (140, 140, 140)   # 最深的灰色
    ]
    
    # 创建对角线渐变效果
    for y in range(size):
        for x in range(size):
            distance = (x + y) / (size * 2)
            
            if distance < 0.33:
                local_ratio = distance / 0.33
                color1 = colors[0]
                color2 = colors[1]
            elif distance < 0.66:
                local_ratio = (distance - 0.33) / 0.33
                color1 = colors[1]
                color2 = colors[2]
            else:
                local_ratio = (distance - 0.66) / 0.34
                color1 = colors[2]
                color2 = colors[3]
            
            r = int(color1[0] + (color2[0] - color1[0]) * local_ratio)
            g = int(color1[1] + (color2[1] - color1[1]) * local_ratio)
            b = int(color1[2] + (color2[2] - color1[2]) * local_ratio)
            
            draw.point((x, y), fill=(r, g, b))
    
    # 绘制文字（深色，iOS 会自动着色）
    _draw_text(draw, size, text="XKAILive", text_color='black')
    
    # 应用圆角
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], corner_radius, fill=255)
    
    output = Image.new('RGB', (size, size), (255, 255, 255))
    output.paste(img, (0, 0))
    output.putalpha(mask)
    
    return output

def _draw_text(draw, size, text="XKAILive", text_color='white'):
    """绘制文字的辅助函数"""
    if size < 128:
        return
    
    padding = int(size * 0.16)
    available_width = size - (padding * 2)
    
    pixel_font_paths = [
        "/System/Library/Fonts/Supplemental/Courier New Bold.ttf",
        "/System/Library/Fonts/Supplemental/Courier New.ttf",
        "/System/Library/Fonts/Supplemental/Menlo.ttc",
        "/System/Library/Fonts/Monaco.ttf",
        "/System/Library/Fonts/Supplemental/Andale Mono.ttf",
    ]
    
    font_path = None
    for path in pixel_font_paths:
        try:
            test_font = ImageFont.truetype(path, 20)
            font_path = path
            break
        except:
            continue
    
    if font_path is None:
        try:
            font_path = "/System/Library/Fonts/Supplemental/Courier New Bold.ttf"
            test_font = ImageFont.truetype(font_path, 20)
        except:
            try:
                font_path = "/System/Library/Fonts/Supplemental/Menlo.ttc"
                test_font = ImageFont.truetype(font_path, 20)
            except:
                font_path = None
    
    if font_path:
        min_font_size = 10
        max_font_size = int(size * 0.3)
        optimal_font_size = min_font_size
        
        while min_font_size <= max_font_size:
            test_size = (min_font_size + max_font_size) // 2
            try:
                test_font = ImageFont.truetype(font_path, test_size)
                bbox = draw.textbbox((0, 0), text, font=test_font)
                text_width = bbox[2] - bbox[0]
                
                if text_width <= available_width:
                    optimal_font_size = test_size
                    min_font_size = test_size + 1
                else:
                    max_font_size = test_size - 1
            except:
                max_font_size = test_size - 1
        
        font = ImageFont.truetype(font_path, optimal_font_size)
        
        try:
            bbox = draw.textbbox((0, 0), text, font=font)
            text_height = bbox[3] - bbox[1]
            
            text_x = padding
            text_y = size - text_height - padding
            
            shadow_offset = max(3, int(size * 0.008))
            if text_color == 'white':
                draw.text((text_x + shadow_offset, text_y + shadow_offset), text, fill=(0, 0, 0, 150), font=font)
                draw.text((text_x, text_y), text, fill='white', font=font)
            else:
                draw.text((text_x + shadow_offset, text_y + shadow_offset), text, fill=(255, 255, 255, 150), font=font)
                draw.text((text_x, text_y), text, fill='black', font=font)
        except:
            pass

def main():
    """主函数"""
    print("🎨 开始生成 XKAILive App Icon...")
    
    # 创建输出目录
    output_dir = "AppIcon_Generated"
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成 1024x1024 的普通图标
    print("📐 生成 1024x1024 图标（Any Appearance）...")
    icon = create_app_icon(1024)
    output_path = os.path.join(output_dir, "AppIcon_1024x1024.png")
    icon.save(output_path, 'PNG')
    print(f"✅ 图标已保存到: {output_path}")
    
    # 生成 1024x1024 的深色模式图标
    print("📐 生成 1024x1024 图标（Dark）...")
    dark_icon = create_dark_app_icon(1024)
    output_path = os.path.join(output_dir, "AppIcon_1024x1024_Dark.png")
    dark_icon.save(output_path, 'PNG')
    print(f"✅ 深色模式图标已保存到: {output_path}")
    
    # 生成 1024x1024 的着色模式图标
    print("📐 生成 1024x1024 图标（Tinted）...")
    tinted_icon = create_tinted_app_icon(1024)
    output_path = os.path.join(output_dir, "AppIcon_1024x1024_Tinted.png")
    tinted_icon.save(output_path, 'PNG')
    print(f"✅ 着色模式图标已保存到: {output_path}")
    
    print("\n✨ 完成！")
    print(f"📁 所有图标已保存到: {output_dir}/")
    print("\n📝 下一步：")
    print("1. 在 Xcode 中打开 Assets.xcassets > AppIcon")
    print("2. 将 AppIcon_1024x1024.png 拖拽到 'Any Appearance' 槽位")
    print("3. 将 AppIcon_1024x1024_Dark.png 拖拽到 'Dark' 槽位")
    print("4. 将 AppIcon_1024x1024_Tinted.png 拖拽到 'Tinted' 槽位")

if __name__ == "__main__":
    main()

