# XKAILive iOS

一个使用 SwiftUI 和 Supabase 开发的现代化 iOS AI 直播社交应用，包含 AI 直播间、AI 粉丝互动、用户认证、动态发布、图片上传等核心功能。

## ✨ 功能特性

### 🔐 用户认证
- ✅ 邮箱注册和登录
- ✅ 会话管理和自动登录
- ✅ 用户资料管理（昵称、头像）
- ✅ 头像上传到 Supabase Storage

### 📱 主页
- ✅ App Store 风格的功能卡片
- ✅ 渐变色背景设计
- ✅ 快速跳转到各个功能模块

### 💬 社区动态
- ✅ 动态列表浏览（按时间倒序）
- ✅ 发布文字动态
- ✅ 上传图片并发布
- ✅ 显示用户头像、昵称和发布时间
- ✅ 下拉刷新功能

### 📹 直播功能
- ✅ 前置摄像头实时预览
- ✅ 用户信息显示
- ✅ 摄像头权限管理

### 👤 个人中心
- ✅ 查看用户信息（头像、昵称、邮箱）
- ✅ 编辑个人资料
- ✅ 上传/更换头像
- ✅ 退出登录

## 🛠 技术栈

### 前端
- **开发语言**：Swift 5.9+
- **UI 框架**：SwiftUI
- **最低支持版本**：iOS 17.0+
- **开发工具**：Xcode 15.0+

### 后端服务
- **认证服务**：Supabase Auth
- **数据库**：Supabase PostgreSQL
- **文件存储**：Supabase Storage
- **实时数据**：Supabase Realtime（预留）

### 架构设计
- **MVVM 模式**：使用 `@ObservableObject` 管理状态
- **服务层分离**：独立的 Service 类处理业务逻辑
- **配置集中管理**：所有配置集中在 `SupabaseConfig.swift`

## 📁 项目结构

```
XKAILive-iOS/
├── README.md                    # 项目说明文档
├── SUPABASE.md                  # Supabase 集成文档
│
├── XKAILive/                      # 主应用目录
│   ├── XKAILiveApp.swift         # 应用入口
│   │
│   ├── Views/                   # 视图层
│   │   ├── ContentView.swift   # 主视图（TabView）
│   │   ├── HomeView.swift      # 主页视图
│   │   ├── CommunityView.swift # 社区视图
│   │   ├── ComposePostView.swift # 发布动态视图
│   │   ├── LiveStreamView.swift # 直播视图
│   │   ├── ProfileView.swift   # 个人中心视图
│   │   ├── LoginView.swift     # 登录视图
│   │   └── RegisterView.swift  # 注册视图
│   │
│   ├── Components/              # 可复用组件
│   │   ├── FeatureCard.swift   # 功能卡片组件
│   │   └── PostCard.swift      # 动态卡片组件
│   │
│   ├── Models/                  # 数据模型
│   │   ├── Post.swift          # 动态数据模型
│   │   ├── Moment.swift        # Moment 数据模型（MomentsService.swift 中）
│   │   └── Profile.swift       # 用户资料模型（ProfileService.swift 中）
│   │
│   ├── Services/                # 服务层
│   │   ├── AuthManager.swift   # 认证管理器
│   │   ├── ProfileService.swift # 用户资料服务
│   │   ├── MomentsService.swift # 动态服务
│   │   └── StorageService.swift # 存储服务
│   │
│   ├── Managers/                # 管理器
│   │   ├── SupabaseManager.swift # Supabase 客户端管理
│   │   └── SupabaseConfig.swift  # Supabase 配置常量
│   │
│   └── Assets.xcassets/         # 资源文件
│
└── SQL Scripts/                 # 数据库脚本（建议）
    ├── create_profiles_table.sql
    ├── create_moments_table.sql
    ├── create_storage_bucket.sql
    └── migrate_existing_users_to_profiles.sql
```

**注意**：当前所有文件都在 `XKdemo/` 根目录下。建议按上述结构组织代码以提高可维护性。

## 🚀 快速开始

### 环境要求

- macOS 14.0+ (推荐 macOS 15.0+)
- Xcode 15.0+ (推荐 Xcode 16.0+)
- iOS 17.0+ 设备或模拟器
- Supabase 账户（免费版即可）

### 安装步骤

#### 1. 克隆项目

```bash
git clone https://github.com/yourusername/XKDemo-iOS.git
cd XKDemo-iOS
```

#### 2. 配置 Supabase

**重要**：使用前必须配置 Supabase 项目！

1. 创建 Supabase 项目
   - 访问 [Supabase](https://supabase.com/) 并创建新项目
   - 记录项目 URL 和 anon key

2. 配置项目
   - 打开 `XKAILive/SupabaseConfig.swift`
   - 替换 `supabaseURL` 和 `supabaseKey` 为你的实际值

3. 初始化数据库
   - 在 Supabase Dashboard 的 SQL Editor 中执行以下脚本：
     - `create_profiles_table.sql` - 创建用户资料表
     - `create_moments_table.sql` - 创建动态表
     - `create_storage_bucket.sql` - 创建存储桶

4. 详细配置说明请参考 [SUPABASE.md](./SUPABASE.md)

#### 3. 添加依赖

1. 打开 `XKAILive.xcodeproj`
2. 在 Xcode 中：**File** > **Add Package Dependencies...**
3. 添加 Supabase Swift SDK：
   ```
   https://github.com/supabase/supabase-swift
   ```
4. 选择版本：**Up to Next Major Version** (2.0.0)

#### 4. 配置开发团队

1. 在 Xcode 中选择项目
2. 选择 **XKdemo** target
3. 在 **Signing & Capabilities** 中设置你的开发团队

#### 5. 运行项目

1. 选择目标设备（真机或模拟器）
2. 按 `Cmd + R` 运行
3. 首次运行会请求摄像头权限（用于直播功能）

## 📖 使用说明

### 注册和登录

1. 首次使用需要注册账号
2. 输入邮箱、密码和昵称
3. 注册成功后自动登录
4. 下次打开应用会自动保持登录状态

### 发布动态

1. 进入"社区"页面
2. 点击右上角"+"按钮
3. 输入文字内容（必填）
4. 可选：点击"添加照片"选择图片
5. 点击"发布"按钮
6. 图片会自动上传到 Supabase Storage

### 修改头像

1. 进入"我的"页面
2. 点击"编辑资料"
3. 点击"选择头像"从相册选择图片
4. 图片会自动上传并更新

## 🔧 开发指南

### 添加新功能

1. **创建视图**：在 `Views/` 目录下创建新的 SwiftUI 视图
2. **创建服务**：在 `Services/` 目录下创建对应的服务类
3. **更新路由**：在 `ContentView.swift` 中添加新的 Tab 或导航

### 修改配置

所有 Supabase 相关配置都在 `SupabaseConfig.swift` 中：
- 修改表名：更新 `profilesTable` 或 `momentsTable`
- 修改存储桶：更新 `imageBucket`
- 修改路径前缀：更新 `avatarPathPrefix` 或 `momentImagePathPrefix`

### 数据库操作

- 查看数据：在 Supabase Dashboard 的 Table Editor 中查看
- 修改表结构：在 SQL Editor 中执行 SQL 脚本
- 查看存储文件：在 Storage 页面查看上传的文件

## 📸 功能截图

### 主页
主页展示功能卡片，采用渐变色背景，支持点击跳转。

### 社区
社区页面显示动态列表，支持发布文字和图片动态，支持下拉刷新。

### 个人中心
个人中心显示用户信息，支持编辑资料和上传头像。

### 直播
直播页面使用前置摄像头，实时显示画面。

## 🎨 UI 设计

- **现代化设计**：采用 SwiftUI 原生组件
- **深色模式支持**：自动适配系统主题
- **流畅动画**：使用系统动画和过渡效果
- **卡片式布局**：App Store 风格的卡片设计

## 🔒 安全注意事项

1. **API Key 安全**：
   - ⚠️ 当前 `SupabaseConfig.swift` 中的 API Key 是硬编码的
   - ✅ 生产环境建议使用环境变量或配置文件（不提交到 Git）
   - ✅ 可以使用 Xcode 的 Build Configuration 管理不同环境的配置

2. **权限管理**：
   - 摄像头权限：已在 Info.plist 中配置
   - 相册权限：使用 PhotosPicker 自动处理

3. **数据安全**：
   - 使用 Supabase RLS（Row Level Security）策略
   - 用户只能访问和修改自己的数据

## 📝 注意事项

1. **Supabase 配置**：使用前必须配置 Supabase 项目
2. **摄像头权限**：真机测试时需要授予摄像头权限
3. **模拟器限制**：模拟器不支持真实摄像头，会显示占位视图
4. **网络连接**：需要网络连接才能使用 Supabase 服务
5. **邮箱验证**：Supabase 默认可能需要邮箱验证，可在 Dashboard 中配置

## 🐛 常见问题

### Q: 登录失败？
A: 检查 `SupabaseConfig.swift` 中的 URL 和 Key 是否正确配置。

### Q: 图片上传失败？
A: 确保已执行 `create_storage_bucket.sql` 脚本创建存储桶。

### Q: 动态列表为空？
A: 确保已执行 `create_moments_table.sql` 脚本创建表。

### Q: 编译错误？
A: 确保已添加 Supabase Swift Package 依赖。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目仅供学习和演示使用。

## 👤 作者

Created by wxk

---

**注意**：这是一个演示项目，部分功能（如直播推流）尚未完全实现。
