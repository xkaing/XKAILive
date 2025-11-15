//
//  ContentView.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var showComposeView = false
    @State private var showLiveStream = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, showComposeView: $showComposeView, showLiveStream: $showLiveStream)
                .tabItem {
                    Label("主页", systemImage: "house.fill")
                }
                .tag(0)
            
            CommunityView(showComposeView: $showComposeView)
                .tabItem {
                    Label("社区", systemImage: "person.3.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .tint(.blue)
        .fullScreenCover(isPresented: $showLiveStream) {
            LiveStreamView()
                .environmentObject(authManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
