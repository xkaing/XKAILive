//
//  Moment.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

/// 动态数据模型，对应 Supabase moments 表
struct Moment: Codable, Identifiable {
    let id: UUID?
    let userName: String
    let userAvatarUrl: String?
    let publishTime: String
    let contentText: String
    let contentImgUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case publishTime = "publish_time"
        case contentText = "content_text"
        case contentImgUrl = "content_img_url"
    }
    
    // 默认初始化方法（用于创建新实例）
    init(
        id: UUID? = nil,
        userName: String,
        userAvatarUrl: String?,
        publishTime: String,
        contentText: String,
        contentImgUrl: String?
    ) {
        self.id = id
        self.userName = userName
        self.userAvatarUrl = userAvatarUrl
        self.publishTime = publishTime
        self.contentText = contentText
        self.contentImgUrl = contentImgUrl
    }
    
    // 自定义解码，处理可能的类型不匹配
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id 可能是 UUID 字符串或 UUID
        var decodedId: UUID?
        if let idString = try? container.decode(String.self, forKey: .id) {
            decodedId = UUID(uuidString: idString)
        } else if let idUUID = try? container.decode(UUID.self, forKey: .id) {
            decodedId = idUUID
        }
        self.id = decodedId
        
        self.userName = try container.decode(String.self, forKey: .userName)
        self.userAvatarUrl = try container.decodeIfPresent(String.self, forKey: .userAvatarUrl)
        self.contentText = try container.decode(String.self, forKey: .contentText)
        self.contentImgUrl = try container.decodeIfPresent(String.self, forKey: .contentImgUrl)
        
        // publish_time 可能是 Date 或 String，统一转换为 String
        if let date = try? container.decode(Date.self, forKey: .publishTime) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.publishTime = formatter.string(from: date)
        } else {
            self.publishTime = try container.decode(String.self, forKey: .publishTime)
        }
    }
    
    // 自定义编码
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userName, forKey: .userName)
        try container.encodeIfPresent(userAvatarUrl, forKey: .userAvatarUrl)
        try container.encode(publishTime, forKey: .publishTime)
        try container.encode(contentText, forKey: .contentText)
        try container.encodeIfPresent(contentImgUrl, forKey: .contentImgUrl)
    }
}

