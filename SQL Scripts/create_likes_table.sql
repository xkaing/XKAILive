-- 创建点赞表 (likes) 的 SQL 脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本
-- 
-- 注意：此脚本会先检查并删除已存在的表（如果存在），然后重新创建
-- 如果表中已有数据，请先备份！

-- 如果表已存在，先删除（谨慎操作！）
DROP TABLE IF EXISTS likes CASCADE;

-- 创建 likes 表
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moment_id BIGINT NOT NULL REFERENCES moments(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL, -- 点赞用户的 ID（Supabase auth.uid() 的字符串形式）
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- 防止同一用户对同一条动态重复点赞
  CONSTRAINT unique_moment_user UNIQUE(moment_id, user_id)
);

-- 创建索引以提高查询性能
CREATE INDEX idx_likes_moment_id ON likes(moment_id);
CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_likes_created_at ON likes(created_at DESC);

-- 创建复合索引，用于快速查询"用户是否点赞了某条动态"
CREATE INDEX idx_likes_moment_user ON likes(moment_id, user_id);

-- 添加注释说明字段用途
COMMENT ON TABLE likes IS '存储用户对动态的点赞记录';
COMMENT ON COLUMN likes.moment_id IS '动态ID，外键关联 moments.id';
COMMENT ON COLUMN likes.user_id IS '点赞用户的ID（Supabase auth.uid() 的字符串形式）';
COMMENT ON COLUMN likes.created_at IS '点赞时间';

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

-- 创建策略：允许用户取消自己的点赞（所有人可以删除，实际应用中可以限制为只能删除自己的）
CREATE POLICY "允许用户取消自己的点赞"
  ON likes
  FOR DELETE
  USING (true);
  
-- 可选：如果需要限制只能删除自己的点赞，使用以下策略替代上面的策略
-- CREATE POLICY "允许用户取消自己的点赞"
--   ON likes
--   FOR DELETE
--   USING (auth.uid()::text = user_id);


