-- 创建评论表 (comments) 的 SQL 脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本

-- 创建 comments 表
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moment_id UUID NOT NULL REFERENCES moments(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL, -- 评论用户的 ID（可以是 Supabase auth.uid() 或用户名）
  user_name TEXT NOT NULL, -- 评论用户的名字（冗余字段，便于查询）
  user_avatar_url TEXT, -- 评论用户的头像 URL（冗余字段，便于查询）
  content TEXT NOT NULL, -- 评论内容
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ, -- 更新时间（如果支持编辑评论）
  
  -- 可选：支持回复评论（二级评论）
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  
  -- 可选：软删除标记
  deleted BOOLEAN DEFAULT false
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_comments_moment_id ON comments(moment_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_parent_comment_id ON comments(parent_comment_id) WHERE parent_comment_id IS NOT NULL;

-- 启用 Row Level Security (RLS)
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- 创建策略：允许所有人读取评论
CREATE POLICY "允许所有人读取评论"
  ON comments
  FOR SELECT
  USING (deleted = false); -- 不显示已删除的评论

-- 创建策略：允许已认证用户发表评论
CREATE POLICY "允许已认证用户发表评论"
  ON comments
  FOR INSERT
  WITH CHECK (true);

-- 创建策略：允许用户更新自己的评论
CREATE POLICY "允许用户更新自己的评论"
  ON comments
  FOR UPDATE
  USING (true); -- 可以根据需要改为 auth.uid()::text = user_id

-- 创建策略：允许用户删除自己的评论
CREATE POLICY "允许用户删除自己的评论"
  ON comments
  FOR DELETE
  USING (true); -- 可以根据需要改为 auth.uid()::text = user_id


