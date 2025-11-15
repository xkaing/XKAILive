//
//  SupabaseConfig.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

/// Supabase 配置常量
struct SupabaseConfig {
    // MARK: - Supabase 连接配置
    /// Supabase 项目 URL
    static let supabaseURL = "https://faltruhdczvgyfltmick.supabase.co"
    
    /// Supabase 匿名密钥（anon key）
    /// 注意：在生产环境中，应该使用更安全的方式存储这些敏感信息
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhbHRydWhkY3p2Z3lmbHRtaWNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2NzI1NDQsImV4cCI6MjA3ODI0ODU0NH0.qNbVMxGAd0nW75AGB4lqnVaK30lRRyD7FAaMiW5BZuA"
    
    // MARK: - 数据库表名
    /// 用户资料表
    static let profilesTable = "profiles"
    
    /// 动态表
    static let momentsTable = "moments"
    
    /// 点赞表
    static let likesTable = "likes"
    
    /// 评论表
    static let commentsTable = "comments"
    
    // MARK: - Storage 存储桶名称
    /// 图片存储桶（用于存储头像和动态图片）
    static let imageBucket = "image"
    
    // MARK: - Storage 路径前缀
    /// 头像存储路径前缀
    static let avatarPathPrefix = "avatars"
    
    /// 动态图片存储路径前缀
    static let momentImagePathPrefix = "moments"
    
    // MARK: - 文件配置
    /// 图片上传质量（0.0 - 1.0）
    static let imageCompressionQuality: CGFloat = 1.0
    
    /// 最大文件大小（字节），5MB
    static let maxFileSize: Int = 5 * 1024 * 1024
    
    /// 允许的图片 MIME 类型
    static let allowedImageMimeTypes = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"]
}

