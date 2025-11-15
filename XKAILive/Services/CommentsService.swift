//
//  CommentsService.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation
import Supabase

/// 评论服务，管理 Supabase comments 表的操作
class CommentsService {
    static let shared = CommentsService()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    /// 获取指定动态的所有评论，按时间正序排列
    /// - Parameter momentId: 动态ID（Int64，对应数据库的 BIGINT）
    /// - Returns: 评论列表
    func fetchComments(momentId: Int64) async throws -> [Comment] {
        do {
            let comments: [Comment] = try await supabase
                .from(SupabaseConfig.commentsTable)
                .select()
                .eq("moment_id", value: String(momentId))
                .eq("deleted", value: false)
                .is("parent_comment_id", value: nil)  // 只获取顶级评论（不包括回复）
                .order("created_at", ascending: true)
                .execute()
                .value
            
            print("✅ 成功获取 \(comments.count) 条评论")
            return comments
        } catch {
            print("❌ 获取评论失败: \(error)")
            throw error
        }
    }
    
    /// 发表评论
    /// - Parameters:
    ///   - momentId: 动态ID（Int64，对应数据库的 BIGINT）
    ///   - userId: 用户ID（字符串格式）
    ///   - userName: 用户昵称
    ///   - userAvatarUrl: 用户头像URL（可选）
    ///   - content: 评论内容
    ///   - parentCommentId: 父评论ID（可选，用于回复功能）
    /// - Returns: 创建的评论
    func createComment(
        momentId: Int64,
        userId: String,
        userName: String,
        userAvatarUrl: String? = nil,
        content: String,
        parentCommentId: Int64? = nil
    ) async throws -> Comment {
        do {
            let comment = Comment(
                momentId: momentId,
                userId: userId,
                userName: userName,
                userAvatarUrl: userAvatarUrl,
                content: content,
                parentCommentId: parentCommentId
            )
            
            let response: Comment = try await supabase
                .from(SupabaseConfig.commentsTable)
                .insert(comment)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ 成功发表评论")
            return response
        } catch {
            print("❌ 发表评论失败: \(error)")
            throw error
        }
    }
    
    /// 删除评论（软删除）
    /// - Parameter commentId: 评论ID（Int64，对应数据库的 BIGINT）
    func deleteComment(commentId: Int64) async throws {
        do {
            try await supabase
                .from(SupabaseConfig.commentsTable)
                .update(["deleted": true])
                .eq("id", value: String(commentId))
                .execute()
            
            print("✅ 成功删除评论: \(commentId)")
        } catch {
            print("❌ 删除评论失败: \(error)")
            throw error
        }
    }
    
    /// 获取评论数
    /// - Parameter momentId: 动态ID（Int64，对应数据库的 BIGINT）
    /// - Returns: 评论数
    func getCommentCount(momentId: Int64) async throws -> Int {
        do {
            let count: Int = try await supabase
                .from(SupabaseConfig.commentsTable)
                .select("id", head: true, count: .exact)
                .eq("moment_id", value: String(momentId))
                .eq("deleted", value: false)
                .execute()
                .count ?? 0
            
            return count
        } catch {
            print("❌ 获取评论数失败: \(error)")
            return 0
        }
    }
}

