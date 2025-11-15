//
//  AuthManager.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation
import SwiftUI
import Combine
import Supabase

/// 认证管理器，负责处理用户登录、注册和会话管理
class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userEmail: String = ""
    @Published var userNickname: String = ""
    @Published var userAvatarUrl: String = ""
    @Published var userId: String = ""
    
    private let supabase = SupabaseManager.shared.client
    
    init() {
        // 从 UserDefaults 读取登录状态
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        self.userNickname = UserDefaults.standard.string(forKey: "userNickname") ?? ""
        self.userAvatarUrl = UserDefaults.standard.string(forKey: "userAvatarUrl") ?? ""
        self.userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        
        // 检查是否有有效的会话
        Task {
            await checkSession()
        }
    }
    
    /// 检查当前会话是否有效
    @MainActor
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            // 会话有效，更新用户信息
            let userId = session.user.id.uuidString
            await loadUserInfo(userId: userId)
            self.isLoggedIn = true
        } catch {
            print("检查会话失败: \(error.localizedDescription)")
            self.isLoggedIn = false
        }
    }
    
    /// 使用邮箱和密码登录
    func signIn(email: String, password: String) async throws {
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            
            let userId = session.user.id.uuidString
            
            await MainActor.run {
                self.userId = userId
                self.userEmail = session.user.email ?? email
                self.isLoggedIn = true
                
                // 保存到 UserDefaults
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(self.userEmail, forKey: "userEmail")
                UserDefaults.standard.set(self.userId, forKey: "userId")
            }
            
            // 加载用户信息（包括昵称和头像）
            await loadUserInfo(userId: userId)
        } catch {
            throw error
        }
    }
    
    /// 使用邮箱和密码注册新用户
    func signUp(email: String, password: String, nickname: String) async throws {
        do {
            // 注册用户
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "nickname": AnyJSON.string(nickname),
                    "full_name": AnyJSON.string(nickname)
                ]
            )
            
            let user = authResponse.user
            let userId = user.id
            
            // 创建用户资料
            do {
                let profile = try await ProfileService.shared.createProfile(
                    userId: userId,
                    nickname: nickname,
                    avatarUrl: nil
                )
                
                await MainActor.run {
                    self.userId = userId.uuidString
                    self.userEmail = email
                    self.userNickname = profile.nickname ?? nickname
                    self.userAvatarUrl = profile.avatarUrl ?? ""
                    self.isLoggedIn = true
                    
                    // 保存到 UserDefaults
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(self.userEmail, forKey: "userEmail")
                    UserDefaults.standard.set(self.userNickname, forKey: "userNickname")
                    UserDefaults.standard.set(self.userAvatarUrl, forKey: "userAvatarUrl")
                    UserDefaults.standard.set(self.userId, forKey: "userId")
                }
            } catch {
                // 如果创建 profile 失败，仍然保存基本用户信息
                print("⚠️ 创建用户资料失败，但用户已注册: \(error)")
                await MainActor.run {
                    self.userId = userId.uuidString
                    self.userEmail = email
                    self.userNickname = nickname
                    self.isLoggedIn = true
                    
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(self.userEmail, forKey: "userEmail")
                    UserDefaults.standard.set(self.userNickname, forKey: "userNickname")
                    UserDefaults.standard.set(self.userId, forKey: "userId")
                }
            }
        } catch {
            throw error
        }
    }
    
    /// 加载用户信息
    @MainActor
    private func loadUserInfo(userId: String) async {
        guard let userIdUUID = UUID(uuidString: userId) else {
            print("❌ 无效的用户 ID: \(userId)")
            return
        }
        
        do {
            // 从 Supabase 获取用户认证信息
            let user = try await supabase.auth.user()
            
            // 更新邮箱信息
            if let email = user.email {
                self.userEmail = email
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
            
            // 从 profiles 表获取用户资料
            if let profile = try await ProfileService.shared.fetchProfile(userId: userIdUUID) {
                // 更新昵称
                if let nickname = profile.nickname, !nickname.isEmpty {
                    self.userNickname = nickname
                    UserDefaults.standard.set(nickname, forKey: "userNickname")
                } else {
                    // 如果 profiles 表中没有昵称，尝试从 userMetadata 获取
                    if let nickname = user.userMetadata["nickname"] as? String {
                        self.userNickname = nickname
                        UserDefaults.standard.set(nickname, forKey: "userNickname")
                    } else if let fullName = user.userMetadata["full_name"] as? String {
                        self.userNickname = fullName
                        UserDefaults.standard.set(fullName, forKey: "userNickname")
                    }
                }
                
                // 更新头像 URL
                if let avatarUrl = profile.avatarUrl, !avatarUrl.isEmpty {
                    self.userAvatarUrl = avatarUrl
                    UserDefaults.standard.set(avatarUrl, forKey: "userAvatarUrl")
                }
            } else {
                // 如果 profiles 表不存在记录，尝试创建（使用 userMetadata 中的信息）
                let nickname = user.userMetadata["nickname"] as? String ?? user.userMetadata["full_name"] as? String
                let profile = try await ProfileService.shared.getOrCreateProfile(
                    userId: userIdUUID,
                    nickname: nickname,
                    avatarUrl: nil
                )
                
                if let nickname = profile.nickname, !nickname.isEmpty {
                    self.userNickname = nickname
                    UserDefaults.standard.set(nickname, forKey: "userNickname")
                }
                
                if let avatarUrl = profile.avatarUrl, !avatarUrl.isEmpty {
                    self.userAvatarUrl = avatarUrl
                    UserDefaults.standard.set(avatarUrl, forKey: "userAvatarUrl")
                }
            }
        } catch {
            print("加载用户信息失败: \(error.localizedDescription)")
        }
    }
    
    /// 登出
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            
            await MainActor.run {
                self.userEmail = ""
                self.userNickname = ""
                self.userAvatarUrl = ""
                self.userId = ""
                self.isLoggedIn = false
                
                // 清除 UserDefaults
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                UserDefaults.standard.removeObject(forKey: "userEmail")
                UserDefaults.standard.removeObject(forKey: "userNickname")
                UserDefaults.standard.removeObject(forKey: "userAvatarUrl")
                UserDefaults.standard.removeObject(forKey: "userId")
            }
        } catch {
            print("登出失败: \(error.localizedDescription)")
        }
    }
    
    /// 更新用户资料
    func updateProfile(nickname: String?, avatarUrl: String?) async throws {
        guard let userIdUUID = UUID(uuidString: self.userId) else {
            throw NSError(
                domain: "AuthManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无效的用户 ID"]
            )
        }
        
        let profile = try await ProfileService.shared.updateProfile(
            userId: userIdUUID,
            nickname: nickname,
            avatarUrl: avatarUrl
        )
        
        await MainActor.run {
            if let nickname = profile.nickname {
                self.userNickname = nickname
                UserDefaults.standard.set(nickname, forKey: "userNickname")
            }
            if let avatarUrl = profile.avatarUrl {
                self.userAvatarUrl = avatarUrl
                UserDefaults.standard.set(avatarUrl, forKey: "userAvatarUrl")
            }
        }
    }
    
    /// 兼容旧版本的登录方法（保留用于向后兼容）
    func login(email: String, nickname: String? = nil) {
        self.userEmail = email
        if let nickname = nickname {
            self.userNickname = nickname
            UserDefaults.standard.set(nickname, forKey: "userNickname")
        }
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(email, forKey: "userEmail")
    }
    
    /// 兼容旧版本的登出方法
    func logout() {
        Task {
            await signOut()
        }
    }
}

