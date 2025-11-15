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
    func fetchMoments() async throws -> [Moment] {
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
}

