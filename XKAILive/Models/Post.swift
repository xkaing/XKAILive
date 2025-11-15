//
//  Post.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation

struct Post: Identifiable {
    let id: UUID
    let userName: String
    let userAvatar: String
    let publishTime: String
    let content: String
    let imageUrl: String? // 可选，如果有图片URL就显示
    
    /// 从 Supabase Moment 转换为 Post
    init(from moment: Moment) {
        self.id = moment.id ?? UUID()
        self.userName = moment.userName
        // 如果 user_avatar_url 为空，使用默认头像
        self.userAvatar = moment.userAvatarUrl ?? ""
        self.content = moment.contentText
        self.imageUrl = moment.contentImgUrl
        
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
    init(id: UUID = UUID(), userName: String, userAvatar: String, publishTime: String, content: String, imageUrl: String?) {
        self.id = id
        self.userName = userName
        self.userAvatar = userAvatar
        self.publishTime = publishTime
        self.content = content
        self.imageUrl = imageUrl
    }
}

