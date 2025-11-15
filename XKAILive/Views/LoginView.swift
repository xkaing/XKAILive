//
//  LoginView.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showRegister: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.3, green: 0.6, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo 和标题区域
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                    
                    Text("欢迎回来")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("使用邮箱登录您的账户")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 50)
                
                // 登录表单
                VStack(spacing: 20) {
                    // 邮箱输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("邮箱")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 20)
                            
                            TextField("请输入邮箱地址", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .foregroundColor(.white)
                                .tint(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .email ? Color.white : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    // 密码输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 20)
                            
                            SecureField("请输入密码", text: $password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .foregroundColor(.white)
                                .tint(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .password ? Color.white : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    // 错误提示
                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }
                    
                    // 登录按钮
                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("登录")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isValidInput ? Color.white : Color.white.opacity(0.5))
                        .foregroundColor(isValidInput ? Color.blue : Color.white.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .disabled(!isValidInput || isLoading)
                    .padding(.top, 8)
                    
                    // 切换到注册
                    HStack(spacing: 4) {
                        Text("还没有账号？")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button(action: {
                            showRegister = true
                        }) {
                            Text("立即注册")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(authManager)
        }
    }
    
    // 验证输入是否有效
    private var isValidInput: Bool {
        !email.isEmpty && isValidEmail(email) && !password.isEmpty
    }
    
    // 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // 处理登录
    private func handleLogin() {
        // 隐藏键盘
        focusedField = nil
        
        // 验证邮箱格式
        guard isValidEmail(email) else {
            errorMessage = "请输入有效的邮箱地址"
            return
        }
        
        // 验证密码
        guard password.count >= 6 else {
            errorMessage = "密码长度至少为6位"
            return
        }
        
        // 开始加载
        isLoading = true
        errorMessage = ""
        
        // 使用 Supabase 进行登录
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // 处理错误信息
                    errorMessage = "登录失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}

