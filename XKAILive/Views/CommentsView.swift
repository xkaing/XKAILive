//
//  CommentsView.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

struct CommentsView: View {
    let post: Post
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var commentText: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 动态内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 动态卡片
                        PostCard(post: post, currentUserId: authManager.userId.isEmpty ? nil : authManager.userId)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        Divider()
                            .padding(.vertical, 12)
                        
                        // 评论列表
                        if isLoading && comments.isEmpty {
                            // 加载状态
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        } else if comments.isEmpty {
                            // 空状态
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("还没有评论")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            // 评论列表
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    }
                }
                
                // 评论输入区域
                if !authManager.userId.isEmpty {
                    Divider()
                    
                    HStack(spacing: 12) {
                        // 用户头像
                        if !authManager.userAvatarUrl.isEmpty, let avatarUrl = URL(string: authManager.userAvatarUrl) {
                            AsyncImage(url: avatarUrl) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 36, height: 36)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.gray)
                        }
                        
                        // 输入框
                        TextField("写评论...", text: $commentText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                            .lineLimit(1...4)
                        
                        // 发送按钮
                        Button(action: {
                            submitComment()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                        }
                        .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadComments()
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    /// 加载评论
    private func loadComments() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedComments = try await CommentsService.shared.fetchComments(momentId: post.id)
                await MainActor.run {
                    self.comments = fetchedComments
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载评论失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// 提交评论
    private func submitComment() {
        let content = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !authManager.userId.isEmpty else {
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                _ = try await CommentsService.shared.createComment(
                    momentId: post.id,
                    userId: authManager.userId,
                    userName: authManager.userNickname.isEmpty ? authManager.userEmail : authManager.userNickname,
                    userAvatarUrl: authManager.userAvatarUrl.isEmpty ? nil : authManager.userAvatarUrl,
                    content: content
                )
                
                await MainActor.run {
                    commentText = ""
                    isSubmitting = false
                    // 重新加载评论列表
                    loadComments()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "发表评论失败: \(error.localizedDescription)"
                    isSubmitting = false
                }
            }
        }
    }
}

/// 评论行组件
struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 用户头像
            if let avatarUrl = comment.userAvatarUrl, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            // 评论内容
            VStack(alignment: .leading, spacing: 4) {
                // 用户昵称和时间
                HStack(spacing: 8) {
                    Text(comment.userName)
                        .font(.system(size: 15, weight: .semibold))
                    
                    if let createdAt = comment.createdAt {
                        Text(formatTime(createdAt))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 评论内容
                Text(comment.content)
                    .font(.system(size: 15))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    /// 格式化时间
    private func formatTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: timeString) {
            let now = Date()
            let interval = now.timeIntervalSince(date)
            
            if interval < 60 {
                return "刚刚"
            } else if interval < 3600 {
                let minutes = Int(interval / 60)
                return "\(minutes)分钟前"
            } else if interval < 86400 {
                let hours = Int(interval / 3600)
                return "\(hours)小时前"
            } else {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "M-d HH:mm"
                return displayFormatter.string(from: date)
            }
        }
        
        return timeString
    }
}

#Preview {
    CommentsView(post: Post(
        id: 1,
        userName: "测试用户",
        userAvatar: "https://picsum.photos/id/1/50/50",
        publishTime: "11-4 12:26",
        content: "这是一条测试动态内容，可以包含多行文字。",
        imageUrl: "https://picsum.photos/id/101/400/300",
        likeCount: 5,
        isLiked: false
    ))
    .environmentObject(AuthManager())
}

