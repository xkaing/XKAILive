//
//  PostCard.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

struct PostCard: View {
    let post: Post
    let currentUserId: String?
    @State private var isLiked: Bool = false
    @State private var likeAnimationScale: CGFloat = 1.0
    @State private var isUpdatingLike: Bool = false
    
    init(post: Post, currentUserId: String? = nil) {
        self.post = post
        self.currentUserId = currentUserId
        // 初始化时从 post 读取点赞状态
        self._isLiked = State(initialValue: post.isLiked)
    }
    
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
                    handleLikeToggle()
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isLiked ? .red : .secondary)
                        .scaleEffect(likeAnimationScale)
                        .opacity(isUpdatingLike ? 0.6 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isUpdatingLike || currentUserId == nil)
                
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
    
    /// 处理点赞切换
    private func handleLikeToggle() {
        guard let currentUserId = currentUserId else {
            return
        }
        
        let momentId = post.id
        
        // 先更新UI状态（乐观更新）
        let newLikedState = !isLiked
        isLiked = newLikedState
        
        // 触发弹跳动画
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            likeAnimationScale = 1.5
        }
        
        // 延迟后恢复
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                likeAnimationScale = 1.0
            }
        }
        
        // 更新数据库
        isUpdatingLike = true
        Task {
            do {
                if newLikedState {
                    try await MomentsService.shared.likeMoment(momentId: momentId, userId: currentUserId)
                } else {
                    try await MomentsService.shared.unlikeMoment(momentId: momentId, userId: currentUserId)
                }
                await MainActor.run {
                    isUpdatingLike = false
                }
            } catch {
                // 如果更新失败，回滚UI状态
                await MainActor.run {
                    isLiked = !newLikedState
                    isUpdatingLike = false
                    print("❌ 更新点赞状态失败: \(error)")
                }
            }
        }
    }
}

#Preview {
    PostCard(post: Post(
        id: 1,
        userName: "测试用户",
        userAvatar: "https://picsum.photos/id/1/50/50",
        publishTime: "11-4 12:26",
        content: "这是一条测试动态内容，可以包含多行文字。",
        imageUrl: "https://picsum.photos/id/101/400/300",
        likeCount: 5,
        isLiked: false
    ), currentUserId: nil)
    .padding()
}

