//
//  HomeView.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

// 卡片配置数据模型
struct CardConfig {
    let title: String
    let description: String  // 简短说明（显示在标题上方）
    let detailDescription: String  // 详细说明（显示在标题下方）
    let gradientColors: [Color]
    let action: (() -> Void)?
    
    init(title: String, description: String, detailDescription: String, gradientColors: [Color], action: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.detailDescription = detailDescription
        self.gradientColors = gradientColors
        self.action = action
    }
}

struct HomeView: View {
    @Binding var selectedTab: Int
    @Binding var showComposeView: Bool
    @Binding var showLiveStream: Bool
    
    // 卡片配置数组
    private var cardConfigs: [CardConfig] {
        [
            CardConfig(
                title: "开直播",
                description: "Just show off then",
                detailDescription: "虚拟直播间，开启直播和你的AI粉丝进行互动，AI粉丝会聊天，发弹幕，刷礼物。粉丝有用户勋章，直播间有弹幕轨道，公告轨道，礼物轨道，等等",
                gradientColors: [
                    Color(red: 0.5, green: 0.2, blue: 0.9),   // 深紫色
                    Color(red: 0.9, green: 0.3, blue: 0.6),   // 粉红色
                    Color(red: 1.0, green: 0.5, blue: 0.3),   // 橙红色
                    Color(red: 1.0, green: 0.7, blue: 0.2)    // 金黄色
                ],
                action: {
                    showLiveStream = true
                }
            ),
            CardConfig(
                title: "发动态",
                description: "Share your moments",
                detailDescription: "和AI粉丝在动态的评论群进行互动聊天",
                gradientColors: [
                    Color(red: 0.2, green: 0.6, blue: 0.9),   // 蓝色
                    Color(red: 0.3, green: 0.8, blue: 0.7),   // 青绿色
                    Color(red: 0.4, green: 0.9, blue: 0.5),   // 绿色
                    Color(red: 0.6, green: 1.0, blue: 0.4)    // 亮绿色
                ],
                action: {
                    selectedTab = 1
                    // 延迟一下确保页面切换完成后再打开发动态页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showComposeView = true
                    }
                }
            ),
            CardConfig(
                title: "待开发",
                description: "More features coming soon",
                detailDescription: "",
                gradientColors: [
                    Color(.gray)
                ]
            )
        ]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 循环渲染所有卡片
                    ForEach(Array(cardConfigs.enumerated()), id: \.offset) { index, config in
                        Button(action: {
                            config.action?()
                        }) {
                            FeatureCard(
                                title: config.title,
                                description: config.description,
                                detailDescription: config.detailDescription,
                                gradientColors: config.gradientColors
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.top, index == 0 ? 8 : 0)
                    }
                }
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("主页")
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0), showComposeView: .constant(false), showLiveStream: .constant(false))
}
