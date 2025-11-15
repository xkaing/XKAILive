-- 为 moments 表添加点赞数和评论数字段的 SQL 脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本
-- 
-- 注意：这些字段是冗余的，用于提高查询性能
-- 实际数据以 likes 和 comments 表为准
-- 可以通过数据库触发器或应用层逻辑来维护这些计数

-- 添加点赞数字段
ALTER TABLE moments 
ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;

-- 添加评论数字段
ALTER TABLE moments 
ADD COLUMN IF NOT EXISTS comment_count INTEGER DEFAULT 0;

-- 创建函数：更新动态的点赞数
CREATE OR REPLACE FUNCTION update_moment_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE moments 
    SET like_count = like_count + 1 
    WHERE id = NEW.moment_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE moments 
    SET like_count = GREATEST(like_count - 1, 0) 
    WHERE id = OLD.moment_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器：自动更新点赞数
DROP TRIGGER IF EXISTS trigger_update_moment_like_count ON likes;
CREATE TRIGGER trigger_update_moment_like_count
  AFTER INSERT OR DELETE ON likes
  FOR EACH ROW
  EXECUTE FUNCTION update_moment_like_count();

-- 创建函数：更新动态的评论数
CREATE OR REPLACE FUNCTION update_moment_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE moments 
    SET comment_count = comment_count + 1 
    WHERE id = NEW.moment_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE moments 
    SET comment_count = GREATEST(comment_count - 1, 0) 
    WHERE id = OLD.moment_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器：自动更新评论数
DROP TRIGGER IF EXISTS trigger_update_moment_comment_count ON comments;
CREATE TRIGGER trigger_update_moment_comment_count
  AFTER INSERT OR DELETE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_moment_comment_count();

-- 初始化现有动态的计数（可选，用于已有数据）
-- UPDATE moments 
-- SET like_count = (
--   SELECT COUNT(*) FROM likes WHERE likes.moment_id = moments.id
-- );
-- 
-- UPDATE moments 
-- SET comment_count = (
--   SELECT COUNT(*) FROM comments WHERE comments.moment_id = moments.id AND deleted = false
-- );


