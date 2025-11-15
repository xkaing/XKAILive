//
//  Moment.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

/// 动态数据模型，对应 Supabase moments 表
struct Moment: Codable, Identifiable {
    let id: Int64?  // BIGINT 类型，对应数据库的 int8
    let userName: String
    let userAvatarUrl: String?
    let publishTime: String
    let contentText: String
    let contentImgUrl: String?
    let likeCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case publishTime = "publish_time"
        case contentText = "content_text"
        case contentImgUrl = "content_img_url"
        case likeCount = "like_count"
    }
    
    // 默认初始化方法（用于创建新实例）
    init(
        id: Int64? = nil,
        userName: String,
        userAvatarUrl: String?,
        publishTime: String,
        contentText: String,
        contentImgUrl: String?,
        likeCount: Int? = nil
    ) {
        self.id = id
        self.userName = userName
        self.userAvatarUrl = userAvatarUrl
        self.publishTime = publishTime
        self.contentText = contentText
        self.contentImgUrl = contentImgUrl
        self.likeCount = likeCount
    }
    
    // 自定义解码，处理可能的类型不匹配
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id 是 BIGINT (Int64)，可能是整数或字符串
        var decodedId: Int64?
        if let idInt = try? container.decode(Int64.self, forKey: .id) {
            decodedId = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int64(idString) {
            decodedId = idInt
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            decodedId = Int64(idInt)
        } else {
            decodedId = try container.decodeIfPresent(Int64.self, forKey: .id)
        }
        self.id = decodedId
        
        self.userName = try container.decode(String.self, forKey: .userName)
        self.userAvatarUrl = try container.decodeIfPresent(String.self, forKey: .userAvatarUrl)
        self.contentText = try container.decode(String.self, forKey: .contentText)
        self.contentImgUrl = try container.decodeIfPresent(String.self, forKey: .contentImgUrl)
        self.likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount)
        
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
        try container.encodeIfPresent(likeCount, forKey: .likeCount)
    }
}

