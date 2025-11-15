//
//  MomentsService.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation
import Supabase

/// 动态服务，管理 Supabase moments 表的操作
class MomentsService {
    static let shared = MomentsService()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    /// 获取所有动态，按发布时间倒序排列
    /// - Parameter currentUserId: 当前用户ID（可选，用于获取点赞状态）
    func fetchMoments(currentUserId: String? = nil) async throws -> [Moment] {
        do {
            let moments: [Moment] = try await supabase
                .from(SupabaseConfig.momentsTable)
                .select()
                .order("publish_time", ascending: false)
                .execute()
                .value
            
            print("✅ 成功获取 \(moments.count) 条动态")
            return moments
        } catch {
            print("❌ 获取动态失败: \(error)")
            if let decodingError = error as? DecodingError {
                print("📋 解码错误详情: \(decodingError)")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("类型不匹配: 期望 \(type), 上下文: \(context)")
                case .valueNotFound(let type, let context):
                    print("值未找到: 类型 \(type), 上下文: \(context)")
                case .keyNotFound(let key, let context):
                    print("键未找到: \(key), 上下文: \(context)")
                case .dataCorrupted(let context):
                    print("数据损坏: \(context)")
                @unknown default:
                    print("未知解码错误")
                }
            }
            throw error
        }
    }
    
    /// 批量检查用户对多个动态的点赞状态
    /// - Parameters:
    ///   - momentIds: 动态ID数组（Int64，对应数据库的 BIGINT）
    ///   - userId: 用户ID
    /// - Returns: 已点赞的动态ID集合
    func getLikedMomentIds(momentIds: [Int64], userId: String) async throws -> Set<Int64> {
        do {
            let momentIdValues = momentIds.map { String($0) }
            let likes: [Like] = try await supabase
                .from(SupabaseConfig.likesTable)
                .select()
                .in("moment_id", values: momentIdValues)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return Set(likes.map { $0.momentId })
        } catch {
            print("❌ 批量获取点赞状态失败: \(error)")
            return []
        }
    }
    
    /// 创建新动态
    func createMoment(
        userName: String,
        userAvatarUrl: String?,
        contentText: String,
        contentImgUrl: String?
    ) async throws -> Moment {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let publishTime = formatter.string(from: Date())
        
        let newMoment = Moment(
            id: nil,
            userName: userName,
            userAvatarUrl: userAvatarUrl,
            publishTime: publishTime,
            contentText: contentText,
            contentImgUrl: contentImgUrl
        )
        
        do {
            let response: Moment = try await supabase
                .from(SupabaseConfig.momentsTable)
                .insert(newMoment)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ 成功创建动态")
            return response
        } catch {
            print("❌ 创建动态失败: \(error)")
            throw error
        }
    }
    
    /// 点赞动态
    /// - Parameters:
    ///   - momentId: 动态ID（Int64，对应数据库的 BIGINT）
    ///   - userId: 用户ID（字符串格式）
    func likeMoment(momentId: Int64, userId: String) async throws {
        do {
            // 插入点赞记录，使用 ON CONFLICT 避免重复点赞
            let like = Like(momentId: momentId, userId: userId)
            
            try await supabase
                .from(SupabaseConfig.likesTable)
                .insert(like)
                .execute()
            
            print("✅ 成功点赞动态: \(momentId)")
        } catch {
            // 检查是否是重复点赞错误（UNIQUE 约束或主键冲突）
            let errorString = String(describing: error)
            if errorString.contains("duplicate") || 
               errorString.contains("unique") || 
               errorString.contains("23505") {
                print("ℹ️ 用户已点赞，忽略")
                return
            }
            print("❌ 点赞动态失败: \(error)")
            throw error
        }
    }
    
    /// 取消点赞动态
    /// - Parameters:
    ///   - momentId: 动态ID（Int64，对应数据库的 BIGINT）
    ///   - userId: 用户ID（字符串格式）
    func unlikeMoment(momentId: Int64, userId: String) async throws {
        do {
            // 删除点赞记录
            try await supabase
                .from(SupabaseConfig.likesTable)
                .delete()
                .eq("moment_id", value: String(momentId))
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ 成功取消点赞动态: \(momentId)")
        } catch {
            print("❌ 取消点赞动态失败: \(error)")
            throw error
        }
    }
    
    /// 检查用户是否点赞了动态
    /// - Parameters:
    ///   - momentId: 动态ID（Int64，对应数据库的 BIGINT）
    ///   - userId: 用户ID（字符串格式）
    /// - Returns: 是否已点赞
    func isLiked(momentId: Int64, userId: String) async throws -> Bool {
        do {
            let likes: [Like] = try await supabase
                .from(SupabaseConfig.likesTable)
                .select()
                .eq("moment_id", value: String(momentId))
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            return !likes.isEmpty
        } catch {
            print("❌ 检查点赞状态失败: \(error)")
            return false
        }
    }
    
    /// 获取动态的点赞数
    /// - Parameter momentId: 动态ID（Int64，对应数据库的 BIGINT）
    /// - Returns: 点赞数
    func getLikeCount(momentId: Int64) async throws -> Int {
        do {
            // 使用 count 查询
            let count: Int = try await supabase
                .from(SupabaseConfig.likesTable)
                .select("id", head: true, count: .exact)
                .eq("moment_id", value: String(momentId))
                .execute()
                .count ?? 0
            
            return count
        } catch {
            print("❌ 获取点赞数失败: \(error)")
            return 0
        }
    }
}

