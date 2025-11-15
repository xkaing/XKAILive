//
//  Comment.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

/// 评论数据模型，对应 Supabase comments 表
struct Comment: Codable, Identifiable {
    let id: Int64  // int8 类型，对应数据库的 BIGINT
    let momentId: Int64  // BIGINT 类型，对应 moments.id
    let userId: String
    let userName: String
    let userAvatarUrl: String?
    let content: String
    let createdAt: String?
    let updatedAt: String?
    let parentCommentId: Int64?  // 父评论 ID（用于回复功能）
    let deleted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case momentId = "moment_id"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case parentCommentId = "parent_comment_id"
        case deleted
    }
    
    init(
        id: Int64 = 0,
        momentId: Int64,
        userId: String,
        userName: String,
        userAvatarUrl: String? = nil,
        content: String,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        parentCommentId: Int64? = nil,
        deleted: Bool? = false
    ) {
        self.id = id
        self.momentId = momentId
        self.userId = userId
        self.userName = userName
        self.userAvatarUrl = userAvatarUrl
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.parentCommentId = parentCommentId
        self.deleted = deleted
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
        
        // moment_id 是 BIGINT (Int64)
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
        self.userName = try container.decode(String.self, forKey: .userName)
        self.userAvatarUrl = try container.decodeIfPresent(String.self, forKey: .userAvatarUrl)
        self.content = try container.decode(String.self, forKey: .content)
        
        // parent_comment_id 是可选字段
        var decodedParentCommentId: Int64?
        if let parentIdInt = try? container.decode(Int64.self, forKey: .parentCommentId) {
            decodedParentCommentId = parentIdInt
        } else if let parentIdString = try? container.decode(String.self, forKey: .parentCommentId),
                  let parentIdInt = Int64(parentIdString) {
            decodedParentCommentId = parentIdInt
        } else if let parentIdInt = try? container.decode(Int.self, forKey: .parentCommentId) {
            decodedParentCommentId = Int64(parentIdInt)
        } else {
            decodedParentCommentId = try container.decodeIfPresent(Int64.self, forKey: .parentCommentId)
        }
        self.parentCommentId = decodedParentCommentId
        
        self.deleted = try container.decodeIfPresent(Bool.self, forKey: .deleted) ?? false
        
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
    
    // 自定义编码，插入新记录时排除 id 字段（让数据库自动生成）
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // 只有当 id 不为默认值（0）时才编码，插入新记录时 id=0 会被排除
        if id != 0 {
            try container.encode(id, forKey: .id)
        }
        
        try container.encode(momentId, forKey: .momentId)
        try container.encode(userId, forKey: .userId)
        try container.encode(userName, forKey: .userName)
        try container.encodeIfPresent(userAvatarUrl, forKey: .userAvatarUrl)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(parentCommentId, forKey: .parentCommentId)
        try container.encodeIfPresent(deleted, forKey: .deleted)
    }
}

