-- 清空 likes 表的所有数据
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本
-- 
-- 注意：此操作会删除表中的所有数据，且无法恢复！
-- 执行前请确保已备份重要数据

-- 方法1：使用 TRUNCATE（推荐，更快，会重置序列）
-- 这会清空所有数据，并将 id 序列重置为从 1 开始
TRUNCATE TABLE likes RESTART IDENTITY CASCADE;

-- 如果上面的命令因为外键约束失败，可以使用以下命令：
-- TRUNCATE TABLE likes RESTART IDENTITY;

-- 验证：检查表是否已清空
SELECT 
    COUNT(*) as remaining_rows,
    (SELECT last_value FROM likes_id_seq) as current_sequence_value
FROM likes;

-- 如果上面的查询返回 remaining_rows = 0，说明表已成功清空
-- 如果 current_sequence_value = 0 或 1，说明序列已重置

