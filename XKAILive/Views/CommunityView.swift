//
//  CommunityView.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

struct CommunityView: View {
    @Binding var showComposeView: Bool
    @EnvironmentObject var authManager: AuthManager
    
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loadTask: Task<Void, Never>?
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    // 优化的加载动画
                    VStack(spacing: 24) {
                        // 自定义加载动画
                        ZStack {
                            // 背景圆环
                            Circle()
                                .stroke(
                                    Color.blue.opacity(0.15),
                                    lineWidth: 5
                                )
                                .frame(width: 70, height: 70)
                            
                            // 旋转的圆环 - 使用渐变色
                            Circle()
                                .trim(from: 0, to: 0.75)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .blue,
                                            .blue.opacity(0.6),
                                            .blue.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(
                                        lineWidth: 5,
                                        lineCap: .round
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(rotationAngle))
                        }
                        .onAppear {
                            // 启动旋转动画
                            rotationAngle = 0
                            withAnimation(
                                Animation.linear(duration: 1.2)
                                    .repeatForever(autoreverses: false)
                            ) {
                                rotationAngle = 360
                            }
                        }
                        .onDisappear {
                            rotationAngle = 0
                        }
                        
                        // 加载文字
                        VStack(spacing: 8) {
                            Text("加载中...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("正在获取最新动态")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 400)
                    .padding(.top, 80)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("加载失败")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("重试") {
                            loadPosts()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 50)
                } else if posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("还没有动态")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                } else {
                    VStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostCard(post: post, currentUserId: authManager.userId)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .scrollIndicators(.visible)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("社区")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showComposeView = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showComposeView) {
                ComposePostView(onPostCreated: {
                    loadPosts()
                })
            }
            .refreshable {
                await loadPostsAsync(ignoreCancellation: true)
            }
            .task {
                await loadPostsAsync(ignoreCancellation: false)
            }
            .onDisappear {
                // 视图消失时取消正在进行的任务
                loadTask?.cancel()
            }
        }
    }
    
    /// 加载动态列表
    private func loadPosts() {
        // 取消之前的任务
        loadTask?.cancel()
        
        loadTask = Task {
            await loadPostsAsync(ignoreCancellation: false)
        }
    }
    
    /// 异步加载动态列表
    /// - Parameter ignoreCancellation: 是否忽略取消错误（用于下拉刷新）
    private func loadPostsAsync(ignoreCancellation: Bool = false) async {
        // 取消之前的任务
        loadTask?.cancel()
        
        // 创建新任务
        let task = Task {
            await performLoad(ignoreCancellation: ignoreCancellation)
        }
        loadTask = task
        
        await task.value
    }
    
    /// 执行实际的加载操作
    private func performLoad(ignoreCancellation: Bool) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let moments = try await MomentsService.shared.fetchMoments()
            
            // 批量获取点赞状态（优化性能）
            var posts: [Post] = []
            let currentUserId = authManager.userId.isEmpty ? nil : authManager.userId
            if let currentUserId = currentUserId {
                let momentIds = moments.compactMap { $0.id }
                let likedMomentIds = try await MomentsService.shared.getLikedMomentIds(momentIds: momentIds, userId: currentUserId)
                
                for moment in moments {
                    guard let momentId = moment.id else { continue }
                    let isLiked = likedMomentIds.contains(momentId)
                    posts.append(Post(from: moment, currentUserId: currentUserId, isLiked: isLiked))
                }
            } else {
                posts = moments.map { Post(from: $0, currentUserId: nil, isLiked: false) }
            }
            
            await MainActor.run {
                self.posts = posts
                self.isLoading = false
                print("✅ 成功加载 \(moments.count) 条动态")
            }
        } catch {
            // 检查是否是取消错误（错误代码 -999）
            if let nsError = error as NSError? {
                // 如果是取消错误且设置了忽略，则不显示错误
                if nsError.domain == NSURLErrorDomain && nsError.code == -999 {
                    if ignoreCancellation {
                        await MainActor.run {
                            self.isLoading = false
                        }
                        print("ℹ️ 请求被取消（忽略）")
                        return
                    }
                }
            }
            
            await MainActor.run {
                // 提供更友好的错误信息
                var errorText = error.localizedDescription
                
                // 检查是否是表不存在或权限问题
                if let nsError = error as NSError? {
                    if let errorDescription = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                        errorText = errorDescription
                    }
                    
                    // 检查是否是网络错误
                    if nsError.domain == NSURLErrorDomain {
                        if nsError.code == -999 {
                            errorText = "请求已取消"
                        } else {
                            errorText = "网络连接失败，请检查网络设置"
                        }
                    }
                }
                
                // 检查是否是解码错误
                if error is DecodingError {
                    errorText = "数据格式错误，请检查数据库表结构是否正确"
                }
                
                self.errorMessage = errorText
                self.isLoading = false
                print("❌ 加载动态失败: \(error)")
            }
        }
    }
}

#Preview {
    CommunityView(showComposeView: .constant(false))
        .environmentObject(AuthManager())
}

