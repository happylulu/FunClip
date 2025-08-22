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
