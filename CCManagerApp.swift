import SwiftUI
import SwiftData
import LocalAuthentication

@main
struct CCManagerApp: App {
    @State private var isUnlocked = false
    @State private var authFailed = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CreditCard.self,
            Transaction.self,
            Offer.self,
            CardCategory.self,
            RewardBalance.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if isUnlocked {
                ContentView()
                    .modelContainer(sharedModelContainer)
                    .transition(.opacity)
            } else {
                LockScreenView(isUnlocked: $isUnlocked, authFailed: $authFailed)
                    .onAppear { authenticate() }
            }
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Check if Face ID / Touch ID is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // No biometrics — unlock directly
            withAnimation { isUnlocked = true }
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                localizedReason: "Authenticate to access your cards") { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.easeInOut(duration: 0.4)) { isUnlocked = true }
                } else {
                    authFailed = true
                }
            }
        }
    }
}
