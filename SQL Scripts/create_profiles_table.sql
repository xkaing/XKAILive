-- 创建 profiles 表的 SQL 脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本

-- 创建 profiles 表
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);

-- 启用 Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 创建策略：允许所有人读取用户资料（可以根据需要修改为仅读取公开信息）
CREATE POLICY "允许所有人读取用户资料"
  ON profiles
  FOR SELECT
  USING (true);

-- 创建策略：允许用户读取自己的资料
CREATE POLICY "允许用户读取自己的资料"
  ON profiles
  FOR SELECT
  USING (auth.uid() = id);

-- 创建策略：允许用户插入自己的资料
CREATE POLICY "允许用户创建自己的资料"
  ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 创建策略：允许用户更新自己的资料
CREATE POLICY "允许用户更新自己的资料"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 创建函数：自动更新 updated_at 时间戳
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器：在更新时自动更新 updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

