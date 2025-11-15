//
//  PostCard.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

struct PostCard: View {
    let post: Post
    @State private var isLiked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息区域
            HStack(spacing: 12) {
                // 用户头像 - 如果有 URL 则显示，否则使用默认图标
                if !post.userAvatar.isEmpty, let avatarUrl = URL(string: post.userAvatar) {
                    AsyncImage(url: avatarUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 44, height: 44)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .frame(width: 44, height: 44)
                } else {
                    // 使用默认头像图标
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.gray)
                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 用户昵称
                    Text(post.userName)
                        .font(.system(size: 16, weight: .semibold))
                    
                    // 发布时间
                    Text(post.publishTime)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 动态内容
            Text(post.content)
                .font(.system(size: 15))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // 图片（如果有）
            if let imageUrl = post.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .overlay {
                                ProgressView()
                            }
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                            .cornerRadius(8)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            // 操作区
            HStack {
                // 点赞按钮
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isLiked ? .red : .secondary)
                        .scaleEffect(isLiked ? 1.2 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // 评论按钮
                Button(action: {
                    // TODO: 实现评论功能
                }) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // 分享按钮
                Button(action: {
                    // TODO: 实现分享功能
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // 更多按钮
                Button(action: {
                    // TODO: 实现更多功能
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
    }
}

#Preview {
    PostCard(post: Post(
        userName: "测试用户",
        userAvatar: "https://picsum.photos/id/1/50/50",
        publishTime: "11-4 12:26",
        content: "这是一条测试动态内容，可以包含多行文字。",
        imageUrl: "https://picsum.photos/id/101/400/300"
    ))
    .padding()
}

