import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query var cards: [CreditCard]
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]
    @State private var showSMSImport = false
    @Environment(\.colorScheme) var colorScheme
    
    var totalCreditLimit: Double { cards.reduce(0) { $0 + $1.creditLimit } }
    var totalOutstanding: Double { cards.reduce(0) { $0 + $1.currentOutstanding } }
    var totalAvailable: Double { cards.reduce(0) { $0 + $1.availableLimit } }
    var utilizationPercent: Double {
        guard totalCreditLimit > 0 else { return 0 }
        return (totalOutstanding / totalCreditLimit) * 100
    }
    
    var rewardsThisMonth: Double {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        return transactions
            .filter { $0.date >= startOfMonth && !$0.isCancelled }
            .reduce(0) { $0 + $1.rewardsEarned }
    }
    
    var upcomingDues: [CreditCard] {
        cards.filter { $0.daysUntilDue <= 7 }.sorted { $0.daysUntilDue < $1.daysUntilDue }
    }
    
    var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting header
                    headerSection
                    
                    // Portfolio summary card
                    portfolioCard
                    
                    // Upcoming dues alert
                    if !upcomingDues.isEmpty {
                        dueSoonSection
                    }
                    
                    // Quick stats row
                    quickStatsRow
                    
                    // Recent transactions
                    if !recentTransactions.isEmpty {
                        recentTransactionsSection
                    }
                    
                    // Best card suggestion shortcut
                    bestCardShortcut
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSMSImport = true
                    } label: {
                        Label("Import SMS", systemImage: "message.badge.filled.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    .tint(Color(hex: "D4AF37"))
                }
            }
            .sheet(isPresented: $showSMSImport) {
                SMSImportView()
            }
        }
    }
    
    // MARK: - Header
    var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Your Portfolio")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            Spacer()
            // Cards count badge
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 44, height: 44)
                VStack(spacing: 0) {
                    Text("\(cards.count)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("cards")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 12)
    }
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning ☀️"
        case 12..<17: return "Good afternoon 🌤"
        case 17..<21: return "Good evening 🌆"
        default: return "Good night 🌙"
        }
    }
    
    // MARK: - Portfolio Card
    var portfolioCard: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            
            // Subtle pattern overlay
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "D4AF37").opacity(0.08), Color.clear],
                        startPoint: .topTrailing, endPoint: .bottomLeading
                    )
                )
            
            VStack(spacing: 20) {
                // Outstanding amount
                VStack(spacing: 4) {
                    Text("Total Outstanding")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("₹\(totalOutstanding, format: .number.precision(.fractionLength(0)))")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                // Utilization bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Credit Utilisation")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text("\(utilizationPercent, format: .number.precision(.fractionLength(1)))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(utilizationColor)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.12))
                                .frame(height: 6)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [utilizationColor, utilizationColor.opacity(0.7)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * min(utilizationPercent / 100, 1.0), height: 6)
                                .animation(.easeInOut(duration: 0.8), value: utilizationPercent)
                        }
                    }
                    .frame(height: 6)
                }
                
                Divider().overlay(.white.opacity(0.1))
                
                // Three stats
                HStack(spacing: 0) {
                    statItem("Limit", "₹\(totalCreditLimit.formatted(.number.precision(.fractionLength(0))))", .white)
                    Divider().frame(height: 36).overlay(.white.opacity(0.15))
                    statItem("Available", "₹\(totalAvailable.formatted(.number.precision(.fractionLength(0))))", Color(hex: "D4AF37"))
                    Divider().frame(height: 36).overlay(.white.opacity(0.15))
                    statItem("Rewards", rewardsLabel, Color(hex: "34C759"))
                }
            }
            .padding(22)
        }
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
    }
    
    var utilizationColor: Color {
        if utilizationPercent < 30 { return Color(hex: "34C759") }
        if utilizationPercent < 60 { return Color(hex: "F59F00") }
        return Color(hex: "FF3B30")
    }
    
    var rewardsLabel: String {
        guard let firstCard = cards.first else { return "0" }
        switch firstCard.rewardType {
        case .cashback: return "₹\(rewardsThisMonth, format: .number.precision(.fractionLength(0)))"
        case .points: return "\(Int(rewardsThisMonth)) pts"
        case .miles: return "\(Int(rewardsThisMonth)) mi"
        }
    }
    
    @ViewBuilder
    func statItem(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Due Soon
    var dueSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Payments Due", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "FF9500"))
            
            ForEach(upcomingDues.prefix(3)) { card in
                HStack {
                    Circle()
                        .fill(card.cardColor)
                        .frame(width: 8, height: 8)
                    
                    Text(card.name)
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Text("₹\(card.currentOutstanding, format: .number.precision(.fractionLength(0)))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    
                    Text("in \(card.daysUntilDue)d")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(card.daysUntilDue <= 3 ? .red : Color(hex: "FF9500"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill((card.daysUntilDue <= 3 ? Color.red : Color(hex: "FF9500")).opacity(0.12))
                        )
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "FF9500").opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(hex: "FF9500").opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Quick Stats
    var quickStatsRow: some View {
        HStack(spacing: 12) {
            quickStatCard("Cards", "\(cards.count)", "creditcard.fill", Color(hex: "0A84FF"))
            quickStatCard("This Month", "\(transactionsThisMonth)", "arrow.up.forward.circle.fill", Color(hex: "30D158"))
            quickStatCard("Overdue", "\(overdueCount)", "exclamationmark.circle.fill", overdueCount > 0 ? Color(hex: "FF3B30") : .secondary)
        }
    }
    
    var transactionsThisMonth: Int {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return transactions.filter { $0.date >= start }.count
    }
    
    var overdueCount: Int {
        cards.filter { $0.daysUntilDue < 0 }.count
    }
    
    func quickStatCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Recent Transactions
    var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Spends")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                NavigationLink("See All") {
                    TransactionsView()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "D4AF37"))
            }
            
            VStack(spacing: 1) {
                ForEach(recentTransactions) { txn in
                    TransactionRowView(transaction: txn)
                        .background(Color(.secondarySystemBackground))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Best Card Shortcut
    var bestCardShortcut: some View {
        NavigationLink {
            SmartSuggestionView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "D4AF37").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "D4AF37"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Card Suggest")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Find the best card for any purchase")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}
