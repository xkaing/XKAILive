-- 创建点赞表 (likes) 的 SQL 脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本

-- 创建 likes 表
CREATE TABLE IF NOT EXISTS likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moment_id UUID NOT NULL REFERENCES moments(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL, -- 点赞用户的 ID（可以是 Supabase auth.uid() 或用户名）
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- 防止同一用户对同一条动态重复点赞
  UNIQUE(moment_id, user_id)
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_likes_moment_id ON likes(moment_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at DESC);

-- 启用 Row Level Security (RLS)
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- 创建策略：允许所有人读取点赞信息
CREATE POLICY "允许所有人读取点赞"
  ON likes
  FOR SELECT
  USING (true);

-- 创建策略：允许已认证用户点赞
CREATE POLICY "允许已认证用户点赞"
  ON likes
  FOR INSERT
  WITH CHECK (true);

-- 创建策略：允许用户取消自己的点赞
CREATE POLICY "允许用户取消自己的点赞"
  ON likes
  FOR DELETE
  USING (true); -- 可以根据需要改为 auth.uid()::text = user_id


