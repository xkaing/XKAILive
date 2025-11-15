-- 为现有用户批量创建 profiles 记录的迁移脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本
-- 
-- 注意：此脚本会为所有在 auth.users 表中但没有 profiles 记录的用户创建 profile
-- 如果用户之前在注册时使用了 user_metadata 存储昵称，会尝试迁移过来

-- 为所有现有用户创建 profiles（如果不存在）
-- 从 user_metadata 中提取 nickname 或 full_name 作为初始昵称
INSERT INTO profiles (id, nickname, avatar_url, created_at, updated_at)
SELECT 
    u.id,
    -- 尝试从 user_metadata 中获取昵称
    COALESCE(
        u.raw_user_meta_data->>'nickname',
        u.raw_user_meta_data->>'full_name',
        NULL
    ) as nickname,
    -- 尝试从 user_metadata 中获取头像 URL（如果有的话）
    u.raw_user_meta_data->>'avatar_url' as avatar_url,
    u.created_at,
    now() as updated_at
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL  -- 只处理还没有 profile 的用户
ON CONFLICT (id) DO NOTHING;  -- 如果已存在则跳过

-- 显示迁移结果
SELECT 
    COUNT(*) as total_users,
    (SELECT COUNT(*) FROM profiles) as total_profiles,
    COUNT(*) - (SELECT COUNT(*) FROM profiles) as users_without_profiles
FROM auth.users;

