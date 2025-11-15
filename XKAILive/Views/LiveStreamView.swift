//
//  LiveStreamView.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI
import AVFoundation
import Combine
import Network
import UIKit

// 公屏消息类型
enum MessageType {
    case system
    case chat
}

// 公屏消息模型
struct PublicScreenMessage: Identifiable {
    let id = UUID()
    let content: String
    let messageType: MessageType
    let userNickname: String? // 聊天消息的用户昵称
    let timestamp: Date
    
    init(content: String, messageType: MessageType = .system, userNickname: String? = nil) {
        self.content = content
        self.messageType = messageType
        self.userNickname = userNickname
        self.timestamp = Date()
    }
    
    // 兼容旧代码
    var isSystemMessage: Bool {
        return messageType == .system
    }
}

// 弹幕数据模型
struct DanmakuItem: Identifiable {
    let id = UUID()
    let nickname: String
    let content: String
    let avatarUrl: String?
    let startTime: Date
    let randomY: CGFloat // 随机Y轴位置（0.0 - 1.0，相对于可用区域的比例）
    
    init(nickname: String, content: String, avatarUrl: String? = nil) {
        self.nickname = nickname
        self.content = content
        self.avatarUrl = avatarUrl
        self.startTime = Date()
        // 生成0.0到1.0之间的随机值，用于计算Y轴位置
        self.randomY = CGFloat.random(in: 0.0...1.0)
    }
}

// 礼物数据模型
struct GiftItem: Identifiable {
    let id = UUID()
    let senderNickname: String // 送礼人昵称
    let senderAvatarUrl: String? // 送礼人头像URL
    let giftCount: Int // 礼物数量
    let startTime: Date
    
    init(senderNickname: String, senderAvatarUrl: String? = nil, giftCount: Int = 1) {
        self.senderNickname = senderNickname
        self.senderAvatarUrl = senderAvatarUrl
        self.giftCount = giftCount
        self.startTime = Date()
    }
}

// 摄像头预览视图
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        view.previewLayer = previewLayer
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // 确保预览层 frame 正确设置
        if let previewLayer = uiView.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    // 自定义 UIView 类，用于正确设置预览层
    class CameraPreviewView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            if let previewLayer = previewLayer {
                previewLayer.frame = bounds
            }
        }
    }
}

struct LiveStreamView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var captureSession: AVCaptureSession?
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    @State private var errorMessage = ""
    @State private var networkStatus: String = "良好"
    @State private var networkMonitor: NWPathMonitor?
    @State private var networkQueue: DispatchQueue?
    @State private var showMoreOptions = false
    @State private var publicScreenMessages: [PublicScreenMessage] = []
    @FocusState private var isChatInputFocused: Bool
    @State private var chatInputText: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardShowObserver: NSObjectProtocol?
    @State private var keyboardHideObserver: NSObjectProtocol?
    @State private var danmakuItems: [DanmakuItem] = []
    @State private var danmakuTracks: [Int] = [] // 弹幕轨道，用于管理不同高度的弹幕
    @State private var giftItems: [GiftItem] = [] // 礼物列表
    
    // 检测是否在模拟器上运行
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        ZStack {
            // 摄像头预览
            if isSimulator {
                // 模拟器上显示模拟的摄像头预览
                SimulatorCameraPreview()
                    .ignoresSafeArea()
            } else if cameraPermissionStatus == .authorized, let session = captureSession {
                // 真机上显示真实的摄像头预览
                CameraPreview(session: session)
                    .ignoresSafeArea()
            } else {
                // 权限未授权或摄像头未初始化
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        if cameraPermissionStatus == .denied || cameraPermissionStatus == .restricted {
                            VStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("需要摄像头权限")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("请在设置中允许访问摄像头")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        } else if !errorMessage.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("摄像头初始化失败")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }
            }
            
            // 顶部信息栏
            VStack {
                HStack(alignment: .top) {
                    // 左上角：用户头像和昵称（带背景容器）
                    HStack(spacing: 6) {
                        // 使用登录用户的头像
                        Group {
                            if !authManager.userAvatarUrl.isEmpty,
                               let avatarUrl = URL(string: authManager.userAvatarUrl) {
                                AsyncImage(url: avatarUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.white)
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        
                        // 使用登录用户的昵称
                        Text(authManager.userNickname.isEmpty ? "Anchor" : authManager.userNickname)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 4)
                    .padding(.trailing, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.6))
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    // 右上角：关闭按钮和信息
                    VStack(alignment: .trailing, spacing: 6) {
                        // 关闭按钮（透明背景，在顶部）
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "power")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.clear)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                        
                        // 房间号
                        HStack(spacing: 4) {
                            Text("房间号：1")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.6))
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        // 网络状态
                        HStack(spacing: 6) {
                            Image(systemName: "wifi")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                            Text(networkStatus)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.6))
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 8)
                
                // 礼物轨道（在顶部8px间距位置）
                GiftTrackView(giftItems: $giftItems)
                    .padding(.top, 8)
                    .allowsHitTesting(false) // 礼物轨道不拦截触摸事件
                
                Spacer()
                
                // 弹幕轨道层（覆盖在摄像头预览上）
                GeometryReader { geometry in
                    ZStack {
                        ForEach(danmakuItems) { item in
                            DanmakuView(item: item, trackIndex: 0, screenHeight: geometry.size.height)
                                .offset(y: calculateDanmakuYPosition(item: item, screenHeight: geometry.size.height))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .allowsHitTesting(false) // 弹幕不拦截触摸事件
                
                Spacer()
                
                // 底部区域：左下角公屏和聊天框，右下角更多按钮
                HStack(alignment: .bottom, spacing: 0) {
                    // 左下角：公屏和聊天框
                    VStack(alignment: .leading, spacing: 6) {
                        // 公屏（根据键盘高度调整位置，确保在键盘上方）
                        PublicScreenView(messages: $publicScreenMessages)
                            .frame(width: 280, height: 250)
                            .offset(y: keyboardHeight > 0 ? -keyboardHeight + 16 : 0)
                        
                        // 聊天框
                        HStack(spacing: 6) {
                            // 眨眼表情图标
                            Text("😉")
                                .font(.system(size: 18))
                            
                            ZStack(alignment: .leading) {
                                // 占位符文字（白色）
                                if chatInputText.isEmpty {
                                    Text("聊聊吧...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                // 输入框
                                TextField("", text: $chatInputText)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .focused($isChatInputFocused)
                                    .submitLabel(.send)
                                    .onSubmit {
                                        sendChatMessage()
                                    }
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 44) // 与右侧按钮高度一致
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.6))
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
                    
                    Spacer()
                    
                    // 右下角：更多按钮
                    Button(action: {
                        showMoreOptions = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.6))
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $showMoreOptions) {
            MoreOptionsView(messages: $publicScreenMessages, danmakuItems: $danmakuItems, giftItems: $giftItems)
                .presentationDetents([.height(220)])
        }
        .onAppear {
            checkCameraPermission()
            startNetworkMonitoring()
            loadInitialSystemMessage()
            setupKeyboardObservers()
        }
        .onDisappear {
            stopCamera()
            stopNetworkMonitoring()
            removeKeyboardObservers()
        }
        .alert("需要摄像头权限", isPresented: $showPermissionAlert) {
            Button("取消", role: .cancel) {
                dismiss()
            }
            Button("前往设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("应用需要访问摄像头才能进行直播，请在设置中允许访问。")
        }
    }
    
    private func checkCameraPermission() {
        // 模拟器上不需要检查权限
        #if targetEnvironment(simulator)
        return
        #endif
        
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraPermissionStatus {
        case .notDetermined:
            // 请求权限
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        cameraPermissionStatus = .authorized
                        setupCamera()
                    } else {
                        cameraPermissionStatus = .denied
                        showPermissionAlert = true
                    }
                }
            }
        case .authorized:
            setupCamera()
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            errorMessage = "未知的权限状态"
        }
    }
    
    private func setupCamera() {
        // 模拟器上不需要设置摄像头
        #if targetEnvironment(simulator)
        return
        #endif
        
        // 检查权限
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            DispatchQueue.main.async {
                errorMessage = "摄像头权限未授权"
            }
            return
        }
        
        // 在后台线程配置 session
        DispatchQueue.global(qos: .userInitiated).async {
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            // 获取前置摄像头
            guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                DispatchQueue.main.async {
                    errorMessage = "无法访问前置摄像头"
                }
                return
            }
            
            // 创建输入
            var input: AVCaptureDeviceInput
            do {
                input = try AVCaptureDeviceInput(device: frontCamera)
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "无法创建摄像头输入: \(error.localizedDescription)"
                }
                return
            }
            
            // 配置 session
            session.beginConfiguration()
            
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                session.commitConfiguration()
                DispatchQueue.main.async {
                    errorMessage = "无法添加摄像头输入"
                }
                return
            }
            
            // 不需要输出，只需要预览
            session.commitConfiguration()
            
            // 启动 session
            session.startRunning()
            
            // 在主线程更新 UI
            DispatchQueue.main.async {
                captureSession = session
                errorMessage = ""
            }
        }
    }
    
    private func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    // 开始监控网络状态
    private func startNetworkMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor = monitor
        networkQueue = queue
        
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    // 网络连接正常
                    if path.usesInterfaceType(.wifi) {
                        self.networkStatus = "良好"
                    } else if path.usesInterfaceType(.cellular) {
                        self.networkStatus = "良好"
                    } else {
                        self.networkStatus = "良好"
                    }
                } else {
                    self.networkStatus = "无网络"
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // 停止监控网络状态
    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
        networkQueue = nil
    }
    
    // 加载初始系统消息
    private func loadInitialSystemMessage() {
        let systemMessage = PublicScreenMessage(
            content: "【系统通知】：虽然是虚拟直播间，但是直播间严禁出现违法违规、低俗谩骂等不良内容，一经发现，开发者直接删除其账号。",
            messageType: .system
        )
        publicScreenMessages.append(systemMessage)
    }
    
    // 发送聊天消息
    private func sendChatMessage() {
        // 检查输入内容是否为空
        guard !chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // 获取用户昵称，如果没有则使用默认值
        let userNickname = authManager.userNickname.isEmpty ? "Anchor" : authManager.userNickname
        
        // 创建聊天消息
        let chatMessage = PublicScreenMessage(
            content: chatInputText.trimmingCharacters(in: .whitespacesAndNewlines),
            messageType: .chat,
            userNickname: userNickname
        )
        
        // 添加到公屏消息列表
        publicScreenMessages.append(chatMessage)
        
        // 清空输入框并关闭键盘
        chatInputText = ""
        isChatInputFocused = false
    }
    
    // 设置键盘监听
    private func setupKeyboardObservers() {
        keyboardShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        keyboardHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    // 移除键盘监听
    private func removeKeyboardObservers() {
        if let showObserver = keyboardShowObserver {
            NotificationCenter.default.removeObserver(showObserver)
        }
        if let hideObserver = keyboardHideObserver {
            NotificationCenter.default.removeObserver(hideObserver)
        }
    }
    
    // 计算弹幕Y轴偏移量（分布在屏幕中间区域）
    private func calculateDanmakuYOffset(index: Int, screenHeight: CGFloat) -> CGFloat {
        // 5个轨道，分布在屏幕中间60%的区域
        let trackCount = 5
        let startY = screenHeight * 0.2 // 从屏幕20%位置开始
        let endY = screenHeight * 0.8   // 到屏幕80%位置结束
        let trackSpacing = (endY - startY) / CGFloat(trackCount - 1)
        return startY + CGFloat(index) * trackSpacing - screenHeight / 2 // 相对于屏幕中心
    }
    
    // 计算弹幕Y轴位置（随机分布，限制在屏幕中间1/3区域）
    private func calculateDanmakuYPosition(item: DanmakuItem, screenHeight: CGFloat) -> CGFloat {
        // 弹幕限制在屏幕中间1/3的区域（从33.3%到66.6%）
        let startY: CGFloat = screenHeight * (1.0 / 3.0)  // 从屏幕顶部33.3%开始
        let endY: CGFloat = screenHeight * (2.0 / 3.0)    // 到屏幕顶部66.6%结束
        let availableHeight = endY - startY  // 中间1/3的高度
        
        // 使用弹幕的随机Y值（0.0-1.0）来计算在中间1/3区域内的位置
        let yPosition = startY + (item.randomY * availableHeight)
        
        // 返回相对于屏幕中心的偏移量（因为ZStack默认居中对齐）
        return yPosition - screenHeight / 2
    }
}

// 模拟器摄像头预览（占位视图）
struct SimulatorCameraPreview: View {
    var body: some View {
        ZStack {
            // 渐变背景，模拟摄像头画面
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.15, blue: 0.3),
                    Color(red: 0.15, green: 0.2, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 模拟摄像头画面效果
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("模拟器模式")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text("请在真机上测试摄像头功能")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(24) // 模拟器提示框内边距
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                    )
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

// 公屏视图
struct PublicScreenView: View {
    @Binding var messages: [PublicScreenMessage]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(messages) { message in
                        PublicScreenMessageView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 6)
            }
            .onChange(of: messages.count) { oldValue, newValue in
                // 当有新消息时，滚动到底部
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                // 初始加载时滚动到底部
                if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
}

// 公屏消息视图
struct PublicScreenMessageView: View {
    let message: PublicScreenMessage
    
    var body: some View {
        switch message.messageType {
        case .system:
            // 系统消息：宽度与容器一致
            Text(message.content)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.96, green: 0.88, blue: 0.65)) // 浅黄色/米色
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.3)) // #0000004d 约等于 30% 透明度
                )
        case .chat:
            // 聊天消息：显示用户昵称和聊天内容
            HStack(alignment: .top, spacing: 6) {
                // 用户昵称（浅黄色/米色）
                if let nickname = message.userNickname {
                    Text(nickname + ":")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.96, green: 0.88, blue: 0.65)) // 浅黄色/米色
                }
                
                // 聊天内容（白色）
                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3)) // #0000004d 约等于 30% 透明度
            )
        }
    }
}

// 更多选项弹窗视图
struct MoreOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var messages: [PublicScreenMessage]
    @Binding var danmakuItems: [DanmakuItem]
    @Binding var giftItems: [GiftItem]
    
    // 功能项数据模型
    struct FunctionItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let action: () -> Void
    }
    
    // 功能项列表
    private var functionItems: [FunctionItem] {
        [
            FunctionItem(icon: "message.fill", title: "公屏", action: {
                addChatMessage()
            }),
            FunctionItem(icon: "text.bubble.fill", title: "弹幕", action: {
                addDanmaku()
            }),
            FunctionItem(icon: "gift.fill", title: "礼物", action: {
                addGift()
            }),
            FunctionItem(icon: "megaphone.fill", title: "公告", action: {
                // TODO: 添加公告轨道功能
            }),
            FunctionItem(icon: "person.2.fill", title: "进场", action: {
                // TODO: 添加公屏进场功能
            }),
            FunctionItem(icon: "square.grid.2x2", title: "布局", action: {
                // TODO: 打开布局模式
            })
        ]
    }
    
    // 模拟用户昵称列表
    private let mockNicknames = [
        "AI粉丝001", "AI粉丝002", "AI粉丝003", "AI粉丝004", "AI粉丝005",
        "观众A", "观众B", "观众C", "用户123", "用户456",
        "小星星", "月亮", "太阳", "彩虹", "云朵"
    ]
    
    // 模拟聊天内容列表
    private let mockChatContents = [
        "主播好！",
        "支持支持！",
        "太棒了！",
        "666",
        "来了来了",
        "加油！",
        "真不错",
        "喜欢这个直播间",
        "主播辛苦了",
        "继续加油！",
        "太精彩了",
        "支持主播",
        "很棒的内容",
        "期待更多",
        "赞一个"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 网格布局选项列表（3列，自动换行）
                let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(functionItems) { item in
                        MoreOptionRow(
                            icon: item.icon,
                            title: item.title,
                            action: item.action
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
            }
            .navigationTitle("更多选项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // 添加聊天消息
    private func addChatMessage() {
        let randomNickname = mockNicknames.randomElement() ?? "AI粉丝"
        let randomContent = mockChatContents.randomElement() ?? "支持主播！"
        
        let chatMessage = PublicScreenMessage(
            content: randomContent,
            messageType: .chat,
            userNickname: randomNickname
        )
        
        messages.append(chatMessage)
    }
    
    // 添加弹幕
    private func addDanmaku() {
        let randomNickname = mockNicknames.randomElement() ?? "AI粉丝"
        let randomContent = mockChatContents.randomElement() ?? "支持主播！"
        
        let danmaku = DanmakuItem(
            nickname: randomNickname,
            content: randomContent,
            avatarUrl: nil
        )
        
        withAnimation {
            danmakuItems.append(danmaku)
        }
        
        // 弹幕动画完成后移除（约8秒后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            withAnimation {
                if let index = danmakuItems.firstIndex(where: { $0.id == danmaku.id }) {
                    danmakuItems.remove(at: index)
                }
            }
        }
    }
    
    // 添加礼物
    private func addGift() {
        let randomNickname = mockNicknames.randomElement() ?? "AI粉丝"
        // 随机生成1-99之间的礼物数量
        let randomCount = Int.random(in: 1...99)
        
        let gift = GiftItem(
            senderNickname: randomNickname,
            senderAvatarUrl: nil,
            giftCount: randomCount
        )
        
        withAnimation {
            giftItems.append(gift)
        }
    }
}

// 更多选项行视图
struct MoreOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(height: 28)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 弹幕视图组件
struct DanmakuView: View {
    let item: DanmakuItem
    let trackIndex: Int
    let screenHeight: CGFloat
    @State private var offsetX: CGFloat = 0
    
    // 主页开直播卡片的渐变背景色
    private let gradientColors = [
        Color(red: 0.5, green: 0.2, blue: 0.9),   // 深紫色
        Color(red: 0.9, green: 0.3, blue: 0.6),   // 粉红色
        Color(red: 1.0, green: 0.5, blue: 0.3),   // 橙红色
        Color(red: 1.0, green: 0.7, blue: 0.2)    // 金黄色
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 8) {
                // 左边：账号头像（圆形）
                Group {
                    if let avatarUrl = item.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.white)
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                
                // 右边：昵称和内容
                VStack(alignment: .leading, spacing: 3) {
                    // 上侧：账号昵称
                    Text(item.nickname)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 中间：一条白色的从左边到右边的渐变透明中间线
                    LinearGradient(
                        colors: [Color.white.opacity(1), Color.white.opacity(0.5), Color.white.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    .padding(.leading, -8) // 负值让线的左边紧贴头像右侧
                    
                    // 下侧：用户输入的文字
                    Text(item.content)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 10))
            .background(
                Capsule()
                    .fill(
                        // 样式一
                        Color.gray.opacity(0.6)
                        // 样式二
//                        LinearGradient(
//                            colors: gradientColors,
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            .frame(height: 36) // 弹幕高度
            .fixedSize(horizontal: true, vertical: false) // 水平方向根据内容自适应，垂直方向固定
            .drawingGroup() // 改善文字渲染，让文字更清晰
            .offset(x: offsetX)
            .onAppear {
                let screenWidth = geometry.size.width
                // 从右边开始（屏幕宽度 + 一些额外空间确保完全在屏幕外）
                offsetX = screenWidth + 50
                
                // 动画：从右边滑到左边（完全移出屏幕）
                withAnimation(.linear(duration: 8)) {
                    // 计算弹幕宽度（使用屏幕宽度 + 估算弹幕宽度，确保完全移出）
                    let estimatedWidth: CGFloat = 300 // 估算弹幕最大宽度
                    offsetX = -estimatedWidth
                }
            }
        }
    }
}

// 礼物轨道视图
struct GiftTrackView: View {
    @Binding var giftItems: [GiftItem]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                ForEach(giftItems) { gift in
                    GiftItemView(gift: gift, screenWidth: geometry.size.width)
                        .onAppear {
                            // 动画完成后移除礼物（约3秒后）
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    if let index = giftItems.firstIndex(where: { $0.id == gift.id }) {
                                        giftItems.remove(at: index)
                                    }
                                }
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 60)
    }
}

// 单个礼物项视图
struct GiftItemView: View {
    let gift: GiftItem
    let screenWidth: CGFloat
    @State private var offsetX: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // 送礼人头像（圆形，带橙色边框）
            Group {
                if let avatarUrl = gift.senderAvatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.white)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.orange, lineWidth: 2))
            
            // 昵称和固定文案
            VStack(alignment: .leading, spacing: 2) {
                Text(gift.senderNickname)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("送给了你")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // 礼物图标
            Image(systemName: "gift.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            // 数量（x 数字）
            HStack(spacing: 2) {
                Text("x")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.yellow)
                
                Text("\(gift.giftCount)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange) // 纯色背景（橙色）
        )
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        .offset(x: offsetX)
        .onAppear {
            // 初始位置：在屏幕左侧外（使用屏幕宽度确保完全在屏幕外）
            let estimatedWidth: CGFloat = 300 // 估算礼物条宽度
            offsetX = -screenWidth - estimatedWidth
            
            // 从左边滑入
            withAnimation(.easeOut(duration: 0.5)) {
                offsetX = 0
            }
            
            // 停留一段时间后从左边滑出
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    offsetX = -screenWidth - estimatedWidth
                }
            }
        }
    }
}

// 模糊效果视图
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

#Preview {
    LiveStreamView()
        .environmentObject(AuthManager())
}

