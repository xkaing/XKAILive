# Supabase 集成说明

本文档说明如何在 Xcode 项目中添加 Supabase Swift Package 依赖，并配置 Supabase 客户端。

## 步骤 1: 在 Xcode 中添加 Supabase Swift Package

1. 打开 Xcode 项目 `XKAILive.xcodeproj`

2. 在 Xcode 中，选择菜单：**File** > **Add Package Dependencies...**

3. 在搜索框中输入 Supabase Swift SDK 的 URL：

   ```
   https://github.com/supabase/supabase-swift
   ```

4. 点击 **Add Package**

5. 选择版本规则（建议选择 **Up to Next Major Version**，例如 `2.0.0`）

6. 在 **Add to Target** 中，确保勾选 **XKAILive** target

7. 点击 **Add Package** 完成添加

## 步骤 2: 配置 Supabase 项目

1. 访问 [Supabase 官网](https://supabase.com/) 并登录

2. 创建新项目或使用现有项目

3. 在项目设置中，进入 **Settings** > **API**

4. 复制以下信息：
   - **Project URL** (例如: `https://xxxxx.supabase.co`)
   - **anon public** key (anon/public 密钥)

## 步骤 3: 配置 Supabase 连接

打开 `XKAILive/SupabaseConfig.swift` 文件，将以下占位符替换为你的实际值：

```swift
static let supabaseURL = "YOUR_SUPABASE_URL"
static let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
```

例如：

```swift
static let supabaseURL = "https://xxxxx.supabase.co"
static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**注意**：所有 Supabase 相关配置都集中在 `SupabaseConfig.swift` 文件中，便于管理和维护。

## 步骤 4: 配置 Supabase Storage

### 创建存储桶（Bucket）

为了存储用户头像和动态图片，需要创建 `moment_image` 存储桶：

1. 在 Supabase Dashboard 中，进入 **SQL Editor**

2. 打开项目根目录下的 `SQL Scripts/create_storage_bucket.sql` 文件

3. 复制 SQL 脚本内容，粘贴到 Supabase SQL Editor 中

4. 点击 **Run** 执行脚本

这将创建：

- `moment_image` 存储桶，设置为公开访问
- 文件大小限制：5MB
- 允许的文件类型：JPEG、PNG、GIF、WebP
- 存储策略：允许已认证用户上传，所有人可读取

**或者**，你也可以通过 Supabase Dashboard 手动创建：

1. 进入 **Storage** 页面
2. 点击 **New bucket**
3. 输入名称：`moment_image`
4. 设置为 **Public bucket**
5. 设置文件大小限制和允许的文件类型

### 创建 profiles 表

为了存储用户的头像和昵称，需要创建 `profiles` 表：

1. 在 Supabase Dashboard 中，进入 **SQL Editor**

2. 打开项目根目录下的 `SQL Scripts/create_profiles_table.sql` 文件

3. 复制 SQL 脚本内容，粘贴到 Supabase SQL Editor 中

4. 点击 **Run** 执行脚本

这将创建：

- `profiles` 表，包含 `id`（关联到 `auth.users.id`）、`nickname`、`avatar_url` 等字段
- Row Level Security (RLS) 策略，确保用户只能访问和修改自己的资料
- 自动更新时间戳的触发器

### 关联机制说明

`profiles` 表通过 `id` 字段与 `auth.users` 表关联：

- `profiles.id` 是主键，同时也是外键，引用 `auth.users(id)`
- 使用 `ON DELETE CASCADE`，当用户被删除时，对应的 profile 也会自动删除
- 每个 `auth.users` 中的用户可以有且仅有一个对应的 `profiles` 记录

### 处理现有用户（迁移）

如果你已经有用户在 `auth.users` 表中注册，有两种方式处理：

#### 方式 1：自动创建（推荐用于少量用户）

当现有用户下次登录时，系统会自动为他们创建 `profiles` 记录。代码逻辑在 `AuthManager.loadUserInfo()` 中：

- 如果用户登录时没有 `profiles` 记录，会自动创建
- 会尝试从 `user_metadata` 中迁移昵称等信息

#### 方式 2：批量迁移（推荐用于大量用户）

如果你有很多现有用户，可以使用批量迁移脚本：

1. 在 Supabase Dashboard 中，进入 **SQL Editor**
2. 打开项目根目录下的 `SQL Scripts/migrate_existing_users_to_profiles.sql` 文件
3. 复制 SQL 脚本内容，粘贴到 Supabase SQL Editor 中
4. 点击 **Run** 执行脚本

这个脚本会：

- 为所有现有用户创建 `profiles` 记录
- 从 `user_metadata` 中迁移昵称（如果有的话）
- 显示迁移统计信息

### 为什么使用独立的 profiles 表？

相比直接在 `auth.users` 表的 metadata 中存储数据，使用独立的 `profiles` 表有以下优势：

- ✅ **更灵活**：可以存储更多用户信息（头像、简介、设置等）
- ✅ **更好的权限控制**：通过 RLS 策略精确控制访问权限
- ✅ **更容易查询**：可以轻松查询和筛选用户资料
- ✅ **符合最佳实践**：将认证数据和业务数据分离

## 步骤 5: 测试

1. 运行项目（Cmd + R）

2. 尝试注册新用户

3. 尝试登录

## 注意事项

- **安全性**：在生产环境中，不要将 Supabase 密钥硬编码在代码中。考虑使用：

  - 环境变量
  - Xcode 的 Build Configuration
  - 配置文件（不提交到 Git）

- **邮箱验证**：默认情况下，Supabase 可能需要邮箱验证。你可以在 Supabase Dashboard 的 **Authentication** > **Settings** 中配置。

- **错误处理**：当前实现包含基本的错误处理。你可以根据需要扩展错误处理逻辑。

## 已集成的功能

✅ 用户注册（邮箱 + 密码）  
✅ 用户登录（邮箱 + 密码）  
✅ 用户登出  
✅ 会话管理  
✅ 用户资料管理（昵称、头像）

- 注册时自动创建用户资料
- 登录时自动加载用户资料
- 支持编辑和更新用户资料
- 头像支持上传到 Supabase Storage
- 支持从相册选择图片作为头像

## 后续扩展

你可以使用 Supabase 的其他功能：

- **数据库操作**：使用 `supabase.database` 进行数据查询
- **实时订阅**：使用 `supabase.realtime` 实现实时数据同步
- **存储**：使用 `supabase.storage` 上传和管理文件
- **Edge Functions**：调用 Supabase Edge Functions

更多信息请参考 [Supabase Swift 文档](https://github.com/supabase/supabase-swift)。
