//
//  FeatureCard.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

struct FeatureCard: View {
    let title: String
    let description: String  // 简短说明（显示在标题上方）
    let detailDescription: String  // 详细说明（显示在标题下方）
    let gradientColors: [Color]
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 渐变色背景（自适应高度）
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 左下角文字内容（垂直布局）
            VStack(alignment: .leading, spacing: 6) {
                // 顶部：简短说明
                Text(description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // 中间：标题
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // 底部：详细说明
                if !detailDescription.isEmpty {
                    Text(detailDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    VStack {
        FeatureCard(
            title: "开直播",
            description: "Just show off then",
            detailDescription: "虚拟直播间，开启直播和你的AI粉丝进行互动，AI粉丝会聊天，发弹幕，刷礼物。粉丝有用户勋章，直播间有弹幕轨道，公告轨道，礼物轨道，等等",
            gradientColors: [
                Color(red: 0.5, green: 0.2, blue: 0.9),
                Color(red: 0.9, green: 0.3, blue: 0.6),
                Color(red: 1.0, green: 0.5, blue: 0.3),
                Color(red: 1.0, green: 0.7, blue: 0.2)
            ]
        )
        
        FeatureCard(
            title: "发动态",
            description: "Share your moments",
            detailDescription: "和AI粉丝在动态的评论群进行互动聊天",
            gradientColors: [
                Color(red: 0.2, green: 0.6, blue: 0.9),
                Color(red: 0.3, green: 0.8, blue: 0.7),
                Color(red: 0.4, green: 0.9, blue: 0.5),
                Color(red: 0.6, green: 1.0, blue: 0.4)
            ]
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

