//
//  XKAILiveApp.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import SwiftUI

@main
struct XKAILiveApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
