//
//  Like.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

/// 点赞数据模型，对应 Supabase likes 表
struct Like: Codable, Identifiable {
    let id: Int64  // int8 类型，对应数据库的 BIGINT
    let momentId: Int64  // BIGINT 类型，对应 moments.id
    let userId: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case momentId = "moment_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
    
    init(id: Int64 = 0, momentId: Int64, userId: String, createdAt: String? = nil) {
        self.id = id
        self.momentId = momentId
        self.userId = userId
        self.createdAt = createdAt
    }
    
    // 自定义解码，处理可能的类型不匹配
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id 是 int8 (Int64)，可能是整数或字符串
        var decodedId: Int64
        if let idInt = try? container.decode(Int64.self, forKey: .id) {
            decodedId = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int64(idString) {
            decodedId = idInt
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            decodedId = Int64(idInt)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "Invalid id format, expected int8"
            )
        }
        self.id = decodedId
        
        // moment_id 是 BIGINT (Int64)，可能是整数或字符串
        var decodedMomentId: Int64
        if let momentIdInt = try? container.decode(Int64.self, forKey: .momentId) {
            decodedMomentId = momentIdInt
        } else if let momentIdString = try? container.decode(String.self, forKey: .momentId),
                  let momentIdInt = Int64(momentIdString) {
            decodedMomentId = momentIdInt
        } else if let momentIdInt = try? container.decode(Int.self, forKey: .momentId) {
            decodedMomentId = Int64(momentIdInt)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .momentId,
                in: container,
                debugDescription: "Invalid moment_id format"
            )
        }
        self.momentId = decodedMomentId
        
        self.userId = try container.decode(String.self, forKey: .userId)
        
        // 时间戳可能是 Date 或 String，统一转换为 String
        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.string(from: date)
        } else {
            self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        }
    }
    
    // 自定义编码，插入新记录时排除 id 字段（让数据库自动生成）
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // 只有当 id 不为默认值（0）时才编码，插入新记录时 id=0 会被排除
        if id != 0 {
            try container.encode(id, forKey: .id)
        }
        
        try container.encode(momentId, forKey: .momentId)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

