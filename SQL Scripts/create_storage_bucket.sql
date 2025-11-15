-- 创建 Supabase Storage Bucket 的 SQL 脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此脚本

-- 创建存储桶（如果不存在）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'image',
    'image',
    true,  -- 公开访问
    5242880,  -- 5MB 文件大小限制
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 创建存储策略：允许已认证用户上传文件
CREATE POLICY "允许已认证用户上传图片"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'image');

-- 创建存储策略：允许所有人读取图片（因为 bucket 是公开的）
CREATE POLICY "允许所有人读取图片"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'image');

-- 创建存储策略：允许用户更新自己的文件
CREATE POLICY "允许用户更新自己的文件"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'image' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 创建存储策略：允许用户删除自己的文件
CREATE POLICY "允许用户删除自己的文件"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'image' AND (storage.foldername(name))[1] = auth.uid()::text);

