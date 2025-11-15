//
//  AppIconPreview.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

/// App Icon 预览工具
/// 用于在 Xcode Preview 中预览和设计 App Icon
struct AppIconPreview: View {
    var body: some View {
        ZStack {
            // 背景渐变 - 代表 AI 和直播的科技感
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.1, blue: 0.4),  // 深紫色
                    Color(red: 0.4, green: 0.2, blue: 0.6),   // 紫色
                    Color(red: 0.6, green: 0.3, blue: 0.8)    // 亮紫色
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 主要设计元素
            VStack(spacing: 0) {
                // AI 元素 - 使用几何图形代表 AI
                ZStack {
                    // 外圈 - 代表直播信号
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 180, height: 180)
                    
                    // 内圈 - 代表 AI 核心
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.5, blue: 0.3),  // 橙红色
                                    Color(red: 1.0, green: 0.7, blue: 0.2)    // 金黄色
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .orange.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    // AI 符号 - 使用几何图形
                    VStack(spacing: 4) {
                        // 代表 AI 的抽象符号
                        HStack(spacing: 3) {
                            Circle()
                                .fill(.white)
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(.white.opacity(0.7))
                                .frame(width: 10, height: 10)
                            Circle()
                                .fill(.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                        
                        // 代表直播的波浪线
                        HStack(spacing: 2) {
                            Capsule()
                                .fill(.white)
                                .frame(width: 4, height: 20)
                            Capsule()
                                .fill(.white.opacity(0.8))
                                .frame(width: 4, height: 28)
                            Capsule()
                                .fill(.white)
                                .frame(width: 4, height: 20)
                        }
                    }
                }
            }
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 220)) // iOS App Icon 圆角
    }
}

// 简化版本 - 适合小尺寸显示
struct SimpleAppIcon: View {
    var size: CGFloat = 1024
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.2, blue: 0.5),
                    Color(red: 0.5, green: 0.3, blue: 0.7),
                    Color(red: 0.7, green: 0.4, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 中心图标
            VStack(spacing: size * 0.05) {
                // AI 符号
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.6, blue: 0.3),
                                    Color(red: 1.0, green: 0.8, blue: 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size * 0.4, height: size * 0.4)
                        .shadow(color: .orange.opacity(0.6), radius: size * 0.05, x: 0, y: size * 0.02)
                    
                    // 字母 "AI"
                    Text("AI")
                        .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // 文字 "LIVE"
                Text("LIVE")
                    .font(.system(size: size * 0.08, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(size * 0.01)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.215)) // iOS 标准圆角比例
    }
}

#Preview("App Icon Preview") {
    VStack(spacing: 40) {
        Text("XKAILive App Icon")
            .font(.title)
            .bold()
        
        HStack(spacing: 30) {
            VStack {
                Text("1024x1024")
                    .font(.caption)
                SimpleAppIcon(size: 200)
                    .border(Color.gray.opacity(0.3), width: 1)
            }
            
            VStack {
                Text("App Icon")
                    .font(.caption)
                SimpleAppIcon(size: 100)
            }
            
            VStack {
                Text("Small")
                    .font(.caption)
                SimpleAppIcon(size: 60)
            }
        }
        
        Text("设计说明：")
            .font(.headline)
            .padding(.top)
        
        VStack(alignment: .leading, spacing: 8) {
            Text("• 紫色渐变背景代表科技感和 AI")
            Text("• 橙色圆形代表直播的活力和互动")
            Text("• AI 文字突出 AI 功能")
            Text("• LIVE 文字强调直播特性")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding()
    }
    .padding()
}

