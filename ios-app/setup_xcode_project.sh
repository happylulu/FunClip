#!/bin/bash

# FunClip iOS - Xcode Project Setup Script
# This script creates the Xcode project structure and adds all our files

echo "🚀 Setting up FunClip iOS Xcode Project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed!${NC}"
    echo "Please install Xcode from the App Store first."
    echo "Or run: xcode-select --install"
    exit 1
fi

echo -e "${GREEN}✅ Xcode found${NC}"

# Navigate to ios-app directory
cd /Users/luluhan/FunClip/ios-app

# Create the Xcode project using xcodebuild
echo "📦 Creating Xcode project..."

# Create a simple xcodeproj structure
cat > FunClipApp.xcodeproj/project.pbxproj << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
/* Begin PBXFileReference section */
		/* Core Files */
		1001 /* AuthManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Core/Auth/AuthManager.swift"; sourceTree = "<group>"; };
		1002 /* AuthProtocols.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Core/Auth/AuthProtocols.swift"; sourceTree = "<group>"; };
		1003 /* User.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Models/User.swift"; sourceTree = "<group>"; };
		
		/* Test Files */
		2001 /* AuthManagerTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "FunClipAppTests/AuthManagerTests.swift"; sourceTree = "<group>"; };
		2002 /* AuthMocks.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "FunClipAppTests/Mocks/AuthMocks.swift"; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXGroup section */
		29B97314FDCFA39411CA2CEA /* FunClipApp */ = {
			isa = PBXGroup;
			children = (
				1001 /* AuthManager.swift */,
				1002 /* AuthProtocols.swift */,
				1003 /* User.swift */,
			);
			name = FunClipApp;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXProject section */
		29B97313FDCFA39411CA2CEA /* Project object */ = {
			isa = PBXProject;
			attributes = {
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					FunClipApp = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 1;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = 29B97314FDCFA39411CA2CEA;
			productRefGroup = 29B97314FDCFA39411CA2CEA /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				FunClipApp /* FunClipApp */,
				FunClipAppTests /* FunClipAppTests */,
			);
		};
/* End PBXProject section */
	};
	rootObject = 29B97313FDCFA39411CA2CEA /* Project object */;
}
EOF

echo -e "${GREEN}✅ Project structure created${NC}"

# Create Package.swift for dependencies
echo "📦 Creating Package.swift for dependencies..."

cat > Package.swift << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FunClipApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FunClipApp",
            targets: ["FunClipApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "FunClipApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            path: "FunClipApp"
        ),
        .testTarget(
            name: "FunClipAppTests",
            dependencies: ["FunClipApp"],
            path: "FunClipAppTests"
        ),
    ]
)
EOF

echo -e "${GREEN}✅ Package.swift created${NC}"

# Create the main app entry point
echo "📱 Creating main app file..."

mkdir -p FunClipApp/App
cat > FunClipApp/App/FunClipApp.swift << 'EOF'
import SwiftUI

@main
struct FunClipApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
EOF

# Create ContentView
cat > FunClipApp/App/ContentView.swift << 'EOF'
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
EOF

echo -e "${GREEN}✅ Main app files created${NC}"

# Create a simple auth view for testing
echo "🎨 Creating AuthView..."

mkdir -p FunClipApp/Features/Auth
cat > FunClipApp/Features/Auth/AuthView.swift << 'EOF'
import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image(systemName: "video.badge.checkmark")
                .font(.system(size: 80))
                .foregroundColor(.indigo)
            
            Text("FunClip")
                .font(.largeTitle.bold())
            
            Text("AI-Powered Viral Clips")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Sign in with Apple button
            SignInWithAppleButton(.signIn) { request in
                // Request handled by AuthManager
            } onCompletion: { result in
                Task {
                    do {
                        _ = try await authManager.signInWithApple()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)
            
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                Text("or")
                    .foregroundColor(.secondary)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.horizontal)
            
            // Email/Password fields
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                
                Button(action: signInWithEmail) {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func signInWithEmail() {
        Task {
            do {
                _ = try await authManager.signInWithEmail(email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthManager())
    }
}
EOF

echo -e "${GREEN}✅ Auth UI created${NC}"

# Create placeholder for main tab view
cat > FunClipApp/Features/MainTabView.swift << 'EOF'
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Home")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            Text("Upload")
                .tabItem {
                    Label("Upload", systemImage: "plus.circle.fill")
                }
            
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}
EOF

echo -e "${GREEN}✅ Tab view created${NC}"

# Open in Xcode
echo ""
echo -e "${YELLOW}📂 Project structure ready!${NC}"
echo ""
echo "To open in Xcode, run:"
echo -e "${GREEN}open FunClipApp.xcodeproj${NC}"
echo ""
echo "Or if you prefer Swift Package Manager:"
echo -e "${GREEN}open Package.swift${NC}"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Add Supabase package (File → Add Package Dependencies)"
echo "3. Run tests with ⌘+U"
echo "4. Run app with ⌘+R"
echo ""
echo -e "${GREEN}✨ Setup complete!${NC}"