import SwiftUI

@main
struct FunClipApp: App {
    // Note: We can't use AuthManager without Supabase package
    // For now, just show a simple UI
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}

struct MainContentView: View {
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    
    var body: some View {
        if !isAuthenticated {
            // Simple login screen
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "video.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.indigo)
                
                Text("FunClip")
                    .font(.largeTitle.bold())
                
                Text("AI-Powered Viral Clips")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { isAuthenticated = true }) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
        } else {
            // Main app with tabs
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                CreateView()
                    .tabItem {
                        Label("Create", systemImage: "plus.circle.fill")
                    }
                    .tag(1)
                
                ProfileView(isAuthenticated: $isAuthenticated)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(2)
            }
        }
    }
}

// Home View
struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.indigo)
                
                Text("Welcome to FunClip")
                    .font(.title2.bold())
                
                Text("Start creating viral clips")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("FunClip")
        }
    }
}

// Create View
struct CreateView: View {
    @State private var youtubeURL = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Create Viral Clips")
                            .font(.title.bold())
                        
                        Text("Upload a video or paste a YouTube link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Upload Options
                    VStack(spacing: 20) {
                        // Camera Roll
                        Button(action: { showingAlert = true }) {
                            OptionCard(
                                icon: "photo.stack.fill",
                                title: "Choose from Library",
                                description: "Select a video from your camera roll",
                                color: .indigo
                            )
                        }
                        
                        // YouTube
                        Button(action: { showingAlert = true }) {
                            OptionCard(
                                icon: "play.rectangle.fill",
                                title: "YouTube Video",
                                description: "Process a video from YouTube URL",
                                color: .red
                            )
                        }
                        
                        // Record (disabled)
                        OptionCard(
                            icon: "video.fill",
                            title: "Record Video",
                            description: "Coming soon",
                            color: .gray
                        )
                        .opacity(0.6)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Create")
            .alert("Feature Coming Soon", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Video processing will be available once Supabase is configured.")
            }
        }
    }
}

// Option Card Component
struct OptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// Profile View
struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.indigo)
                        VStack(alignment: .leading) {
                            Text("Demo User")
                                .font(.headline)
                            Text("demo@funclip.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Settings") {
                    HStack {
                        Label("Notifications", systemImage: "bell")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    
                    Label("Privacy", systemImage: "lock")
                    Label("Help", systemImage: "questionmark.circle")
                }
                
                Section {
                    Button(action: { isAuthenticated = false }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
