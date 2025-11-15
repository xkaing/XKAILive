//
//  SupabaseManager.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation
import Supabase

/// Supabase 客户端管理器
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // 从配置文件读取 Supabase URL 和 Key
        // 注意：在生产环境中，应该使用更安全的方式存储这些敏感信息
        guard let supabaseURL = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("无效的 Supabase URL")
        }
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: SupabaseConfig.supabaseKey
        )
    }
}

