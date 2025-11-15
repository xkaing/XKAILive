//
//  ProfileService.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation
import Supabase

/// 用户资料服务，管理 Supabase profiles 表的操作
class ProfileService {
    static let shared = ProfileService()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    /// 获取指定用户的资料
    /// - Parameter userId: 用户 ID
    /// - Returns: 用户资料，如果不存在则返回 nil
    func fetchProfile(userId: UUID) async throws -> Profile? {
        do {
            let profile: Profile? = try await supabase
                .from(SupabaseConfig.profilesTable)
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            if let profile = profile {
                print("✅ 成功获取用户资料: \(userId)")
            } else {
                print("ℹ️ 用户资料不存在: \(userId)")
            }
            return profile
        } catch {
            // 如果是 404 错误（记录不存在），返回 nil 而不是抛出错误
            if let error = error as? NSError,
               let errorDescription = error.userInfo[NSLocalizedDescriptionKey] as? String,
               errorDescription.contains("No rows") || errorDescription.contains("not found") {
                print("ℹ️ 用户资料不存在: \(userId)")
                return nil
            }
            print("❌ 获取用户资料失败: \(error)")
            throw error
        }
    }
    
    /// 创建用户资料
    /// - Parameters:
    ///   - userId: 用户 ID
    ///   - nickname: 昵称
    ///   - avatarUrl: 头像 URL
    /// - Returns: 创建的用户资料
    func createProfile(
        userId: UUID,
        nickname: String? = nil,
        avatarUrl: String? = nil
    ) async throws -> Profile {
        let newProfile = Profile(
            id: userId,
            nickname: nickname,
            avatarUrl: avatarUrl
        )
        
        do {
            let response: Profile = try await supabase
                .from(SupabaseConfig.profilesTable)
                .insert(newProfile)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ 成功创建用户资料: \(userId)")
            return response
        } catch {
            print("❌ 创建用户资料失败: \(error)")
            throw error
        }
    }
    
    /// 更新用户资料
    /// - Parameters:
    ///   - userId: 用户 ID
    ///   - nickname: 昵称（可选）
    ///   - avatarUrl: 头像 URL（可选）
    /// - Returns: 更新后的用户资料
    func updateProfile(
        userId: UUID,
        nickname: String? = nil,
        avatarUrl: String? = nil
    ) async throws -> Profile {
        var updateData: [String: AnyJSON] = [:]
        
        if let nickname = nickname {
            updateData["nickname"] = .string(nickname)
        }
        if let avatarUrl = avatarUrl {
            updateData["avatar_url"] = .string(avatarUrl)
        }
        
        guard !updateData.isEmpty else {
            throw NSError(
                domain: "ProfileService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "没有要更新的数据"]
            )
        }
        
        do {
            let response: Profile = try await supabase
                .from(SupabaseConfig.profilesTable)
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ 成功更新用户资料: \(userId)")
            return response
        } catch {
            print("❌ 更新用户资料失败: \(error)")
            throw error
        }
    }
    
    /// 获取或创建用户资料（如果不存在则创建）
    /// - Parameters:
    ///   - userId: 用户 ID
    ///   - nickname: 默认昵称（如果资料不存在）
    ///   - avatarUrl: 默认头像 URL（如果资料不存在）
    /// - Returns: 用户资料
    func getOrCreateProfile(
        userId: UUID,
        nickname: String? = nil,
        avatarUrl: String? = nil
    ) async throws -> Profile {
        // 先尝试获取
        if let profile = try await fetchProfile(userId: userId) {
            return profile
        }
        
        // 如果不存在，则创建
        return try await createProfile(userId: userId, nickname: nickname, avatarUrl: avatarUrl)
    }
}

