import SwiftUI

@main
struct FunClipApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .task {
                    // Check auth status on launch
                    try? await authManager.checkAuthStatus()
                }
        }
    }
}
