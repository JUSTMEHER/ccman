import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            CardsListView()
                .tabItem {
                    Label("Cards", systemImage: "creditcard.fill")
                }
                .tag(1)
            
            TransactionsView()
                .tabItem {
                    Label("Spends", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(2)
            
            OffersView()
                .tabItem {
                    Label("Offers", systemImage: "tag.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(Color(hex: "D4AF37"))  // Gold accent — no purple
    }
}
