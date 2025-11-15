# 评论和点赞功能数据库设计方案

## 设计概述

本方案采用**分离表设计**，为评论和点赞功能创建独立的数据库表。这是关系型数据库中的标准做法，具有以下优势：

### 优势

1. **查询性能好**：可以快速统计点赞数、评论数
2. **扩展性强**：可以轻松添加更多功能（如点赞时间、评论回复等）
3. **数据完整性**：通过外键约束保证数据一致性
4. **支持复杂查询**：可以查询"用户点赞的所有动态"、"动态的所有评论"等
5. **符合规范化设计**：避免数据冗余，便于维护

## 数据库表结构

### 1. `likes` 表（点赞表）

存储用户对动态的点赞记录。

**字段说明：**

- `id`: 主键，UUID
- `moment_id`: 动态 ID，外键关联 `moments.id`
- `user_id`: 点赞用户的 ID
- `created_at`: 点赞时间
- `UNIQUE(moment_id, user_id)`: 防止同一用户重复点赞

**索引：**

- `moment_id`: 快速查询某条动态的所有点赞
- `user_id`: 快速查询某用户的所有点赞
- `created_at`: 按时间排序

### 2. `comments` 表（评论表）

存储用户对动态的评论。

**字段说明：**

- `id`: 主键，UUID
- `moment_id`: 动态 ID，外键关联 `moments.id`
- `user_id`: 评论用户的 ID
- `user_name`: 评论用户的名字（冗余字段，便于查询）
- `user_avatar_url`: 评论用户的头像 URL（冗余字段，便于查询）
- `content`: 评论内容
- `created_at`: 评论时间
- `updated_at`: 更新时间（如果支持编辑）
- `parent_comment_id`: 父评论 ID（支持二级评论/回复）
- `deleted`: 软删除标记

**索引：**

- `moment_id`: 快速查询某条动态的所有评论
- `user_id`: 快速查询某用户的所有评论
- `created_at`: 按时间排序
- `parent_comment_id`: 查询回复评论

### 3. `moments` 表增强

在原有 `moments` 表基础上添加计数字段（可选，用于提高性能）：

- `like_count`: 点赞数（冗余字段，通过触发器自动维护）
- `comment_count`: 评论数（冗余字段，通过触发器自动维护）

**注意**：这些计数字段是冗余的，实际数据以 `likes` 和 `comments` 表为准。添加这些字段的目的是：

- 避免每次查询都要 COUNT，提高性能
- 通过数据库触发器自动维护，保证数据一致性

## 执行顺序

1. **首先执行** `create_likes_table.sql` - 创建点赞表
2. **然后执行** `create_comments_table.sql` - 创建评论表
3. **最后执行** `add_counts_to_moments.sql` - 为 moments 表添加计数字段和触发器

## 使用示例

### 查询动态的点赞数

```sql
-- 方式1：从 likes 表统计（准确）
SELECT COUNT(*) FROM likes WHERE moment_id = 'xxx';

-- 方式2：从 moments 表读取（快速，但可能略有延迟）
SELECT like_count FROM moments WHERE id = 'xxx';
```

### 查询动态的所有评论

```sql
SELECT * FROM comments
WHERE moment_id = 'xxx' AND deleted = false
ORDER BY created_at ASC;
```

### 查询用户是否点赞了某条动态

```sql
SELECT EXISTS(
  SELECT 1 FROM likes
  WHERE moment_id = 'xxx' AND user_id = 'user123'
);
```

### 点赞操作

```sql
-- 点赞
INSERT INTO likes (moment_id, user_id)
VALUES ('moment_id', 'user_id')
ON CONFLICT (moment_id, user_id) DO NOTHING;

-- 取消点赞
DELETE FROM likes
WHERE moment_id = 'moment_id' AND user_id = 'user_id';
```

## 安全策略（RLS）

所有表都启用了 Row Level Security (RLS)：

- **读取权限**：所有人可以读取（可根据需要限制）
- **写入权限**：已认证用户可以点赞/评论
- **删除权限**：用户可以删除自己的点赞/评论

可以根据实际需求修改 RLS 策略。

## 性能优化建议

1. **使用计数字段**：如果动态列表需要频繁显示点赞数和评论数，建议使用 `moments.like_count` 和 `moments.comment_count`
2. **分页加载评论**：评论列表使用分页，避免一次性加载过多数据
3. **缓存热门数据**：对于热门动态，可以考虑缓存点赞数和评论数

## 扩展功能

基于这个设计，可以轻松扩展以下功能：

1. **评论回复**：通过 `parent_comment_id` 字段支持二级评论
2. **点赞通知**：通过 `likes.created_at` 可以查询最新的点赞
3. **用户互动统计**：可以统计用户的点赞数、评论数等
4. **评论编辑**：通过 `updated_at` 字段支持评论编辑功能
5. **评论排序**：可以按时间、点赞数等排序
