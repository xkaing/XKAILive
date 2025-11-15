//
//  Like.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

/// 点赞数据模型，对应 Supabase likes 表
struct Like: Codable, Identifiable {
    let id: UUID
    let momentId: Int64  // BIGINT 类型，对应 moments.id
    let userId: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case momentId = "moment_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), momentId: Int64, userId: String, createdAt: String? = nil) {
        self.id = id
        self.momentId = momentId
        self.userId = userId
        self.createdAt = createdAt
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
}

