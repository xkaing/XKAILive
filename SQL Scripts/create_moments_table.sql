-- 创建 moments 表的 SQL 脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本

-- 创建 moments 表
CREATE TABLE IF NOT EXISTS moments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_name TEXT NOT NULL,
  user_avatar_url TEXT,
  publish_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  content_text TEXT NOT NULL,
  content_img_url TEXT
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_moments_publish_time ON moments(publish_time DESC);

-- 启用 Row Level Security (RLS)
ALTER TABLE moments ENABLE ROW LEVEL SECURITY;

-- 创建策略：允许所有人读取（可以根据需要修改）
CREATE POLICY "允许所有人读取动态"
  ON moments
  FOR SELECT
  USING (true);

-- 创建策略：允许已认证用户插入（可以根据需要修改）
CREATE POLICY "允许已认证用户发布动态"
  ON moments
  FOR INSERT
  WITH CHECK (true);

-- 如果需要允许更新和删除，可以添加以下策略：
-- CREATE POLICY "允许用户更新自己的动态"
--   ON moments
--   FOR UPDATE
--   USING (auth.uid()::text = user_id);
-- 
-- CREATE POLICY "允许用户删除自己的动态"
--   ON moments
--   FOR DELETE
--   USING (auth.uid()::text = user_id);

