//
//  Post.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

struct Post: Identifiable {
    let id: Int64  // BIGINT 类型，对应数据库的 int8
    let userName: String
    let userAvatar: String
    let publishTime: String
    let content: String
    let imageUrl: String? // 可选，如果有图片URL就显示
    let likeCount: Int // 点赞数
    var isLiked: Bool // 当前用户是否已点赞（可变，因为需要更新）
    
    /// 从 Supabase Moment 转换为 Post
    init(from moment: Moment, currentUserId: String? = nil, isLiked: Bool = false) {
        self.id = moment.id ?? 0
        self.userName = moment.userName
        // 如果 user_avatar_url 为空，使用默认头像
        self.userAvatar = moment.userAvatarUrl ?? ""
        self.content = moment.contentText
        self.imageUrl = moment.contentImgUrl
        self.likeCount = moment.likeCount ?? 0
        self.isLiked = isLiked
        
        // 格式化发布时间
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: moment.publishTime) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "M-d HH:mm"
            self.publishTime = displayFormatter.string(from: date)
        } else {
            self.publishTime = moment.publishTime
        }
    }
    
    /// 兼容旧版本的初始化方法
    init(id: Int64 = 0, userName: String, userAvatar: String, publishTime: String, content: String, imageUrl: String?, likeCount: Int = 0, isLiked: Bool = false) {
        self.id = id
        self.userName = userName
        self.userAvatar = userAvatar
        self.publishTime = publishTime
        self.content = content
        self.imageUrl = imageUrl
        self.likeCount = likeCount
        self.isLiked = isLiked
    }
}

