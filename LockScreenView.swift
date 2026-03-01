import SwiftUI
import LocalAuthentication

struct LockScreenView: View {
    @Binding var isUnlocked: Bool
    @Binding var authFailed: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 44, weight: .thin))
                        .foregroundStyle(Color(hex: "D4AF37"))
                }
                
                VStack(spacing: 8) {
                    Text("CC Manager")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("Your personal card vault")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Auth button
                VStack(spacing: 16) {
                    if authFailed {
                        Text("Authentication failed")
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                    
                    Button {
                        authenticate()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: biometricIcon)
                                .font(.system(size: 20))
                            Text(biometricLabel)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.primary)
                        )
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
    
    var biometricIcon: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType == .faceID ? "faceid" : "touchid"
        }
        return "lock.open.fill"
    }
    
    var biometricLabel: String {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType == .faceID ? "Unlock with Face ID" : "Unlock with Touch ID"
        }
        return "Unlock"
    }
    
    func authenticate() {
        authFailed = false
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            withAnimation { isUnlocked = true }
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                localizedReason: "Access your credit card manager") { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.easeInOut(duration: 0.4)) { isUnlocked = true }
                } else {
                    withAnimation { authFailed = true }
                }
            }
        }
    }
}
