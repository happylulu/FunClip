import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .unknown, .loading:
                ProgressView("Loading...")
                    .task {
                        try? await authManager.checkAuthStatus()
                    }
            case .authenticated:
                MainTabView()
            case .unauthenticated:
                AuthView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
    }
}
