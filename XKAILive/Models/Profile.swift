//
//  Profile.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

/// 用户资料数据模型，对应 Supabase profiles 表
struct Profile: Codable, Identifiable {
    let id: UUID
    let nickname: String?
    let avatarUrl: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // 默认初始化方法（用于创建新实例）
    init(
        id: UUID,
        nickname: String? = nil,
        avatarUrl: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 自定义解码，处理可能的类型不匹配
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id 可能是 UUID 字符串或 UUID
        var decodedId: UUID
        if let idString = try? container.decode(String.self, forKey: .id) {
            guard let uuid = UUID(uuidString: idString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .id,
                    in: container,
                    debugDescription: "Invalid UUID string"
                )
            }
            decodedId = uuid
        } else {
            decodedId = try container.decode(UUID.self, forKey: .id)
        }
        self.id = decodedId
        
        self.nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        
        // 时间戳可能是 Date 或 String，统一转换为 String
        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.string(from: date)
        } else {
            self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        }
        
        if let date = try? container.decode(Date.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.updatedAt = formatter.string(from: date)
        } else {
            self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        }
    }
}

