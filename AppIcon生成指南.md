# XKAILive App Icon 生成指南

## 方法一：使用在线工具（推荐）

### 1. AppIcon.co（最简单）

- 访问：https://www.appicon.co/
- 步骤：
  1. 上传一张 **1024x1024** 的 PNG 图片
  2. 选择 iOS 平台
  3. 点击生成
  4. 下载生成的图标包
  5. 解压后，将所有图片拖拽到 Xcode 的 `AppIcon.appiconset` 中

### 2. IconKitchen

- 访问：https://icon.kitchen/
- 支持自定义设计，可以添加文字、图标等

### 3. MakeAppIcon

- 访问：https://makeappicon.com/
- 简单易用，支持多种平台

## 方法二：使用设计工具

### 使用 Figma/Sketch/Photoshop

1. 创建 1024x1024 的画布
2. 设计图标（参考 `AppIconPreview.swift` 中的设计）
3. 导出为 PNG（1024x1024）
4. 使用上述在线工具生成所有尺寸

## 方法三：使用 SwiftUI 预览生成

我已经为你创建了 `AppIconPreview.swift`，你可以：

1. 在 Xcode 中打开 `AppIconPreview.swift`
2. 使用 Preview 查看设计效果
3. 调整颜色、样式等
4. 使用 Xcode 的截图功能或第三方工具导出为图片

### 导出步骤：

1. 运行 Preview
2. 使用截图工具（如 CleanShot X）截取 1024x1024 的图片
3. 或者使用在线工具将预览图转换为图标

## 设计建议

基于 XKAILive 的主题（AI 直播），建议：

### 颜色方案

- **主色**：紫色渐变（科技感、AI）
- **强调色**：橙色/金色（活力、直播）
- **文字**：白色（清晰、现代）

### 设计元素

- AI 相关：几何图形、抽象符号
- 直播相关：圆形、波浪线、信号图标
- 品牌：XK 或 AI 字母组合

## 当前设计预览

我已经在 `AppIconPreview.swift` 中创建了一个基础设计：

- 紫色渐变背景
- 橙色圆形中心
- AI 和 LIVE 文字

你可以在 Xcode Preview 中查看并调整。

## 添加到项目

生成图标后：

1. 打开 Xcode
2. 在项目导航器中找到 `Assets.xcassets` > `AppIcon`
3. 将 `AppIcon_1024x1024.png` 拖拽到 **Any Appearance** 槽位中（1024x1024）
4. **可选**：如果需要支持深色模式，可以将同一个图标也拖拽到 **Dark** 槽位
5. **可选**：如果需要支持着色图标，可以将同一个图标也拖拽到 **Tinted** 槽位

**注意**：iOS App Icon 只需要 1024x1024 一个尺寸，Xcode 会自动生成其他所有尺寸。

## 必需尺寸

iOS App Icon **只需要一个尺寸**：

- **1024x1024（必需）** - 这是唯一需要提供的尺寸
- Xcode 会自动从 1024x1024 图标生成所有其他尺寸（20pt、29pt、40pt、60pt 等）
- 不需要手动提供其他尺寸的图标

## 注意事项

1. **不要添加圆角**：iOS 会自动添加圆角
2. **使用 PNG 格式**：确保背景透明或纯色
3. **避免文字过小**：在小尺寸下可能看不清
4. **测试不同尺寸**：确保在所有尺寸下都清晰可见
