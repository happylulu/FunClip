import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            UploadView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(.indigo)
    }
}

// MARK: - Home View
struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "video.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.indigo)
                    .padding()
                
                Text("Welcome to FunClip")
                    .font(.title2.bold())
                
                Text("Start creating viral clips")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("FunClip")
        }
    }
}

// MARK: - Upload View (now uses VideoUploadView)
struct UploadView: View {
    var body: some View {
        VideoUploadView()
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.indigo)
                        VStack(alignment: .leading) {
                            if case .authenticated(let user) = authManager.authState {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Sign Out") {
                        Task {
                            try? await authManager.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}
