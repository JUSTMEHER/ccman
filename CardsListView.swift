import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Cards List
struct CardsListView: View {
    @Query(sort: \CreditCard.createdAt) var cards: [CreditCard]
    @State private var showAddCard = false
    @State private var selectedCard: CreditCard?
    
    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    emptyState
                } else {
                    cardsList
                }
            }
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddCard = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .tint(Color(hex: "D4AF37"))
                }
            }
            .sheet(isPresented: $showAddCard) {
                AddCardView()
            }
        }
    }
    
    var cardsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Horizontal card carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(cards) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                CreditCardWidget(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Card list below
                VStack(spacing: 12) {
                    ForEach(cards) { card in
                        NavigationLink {
                            CardDetailView(card: card)
                        } label: {
                            CardListRowView(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(Color(hex: "D4AF37").opacity(0.8))
            
            VStack(spacing: 8) {
                Text("No Cards Yet")
                    .font(.system(size: 22, weight: .bold))
                Text("Add your first credit card to start tracking rewards, spending, and due dates.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showAddCard = true
            } label: {
                Label("Add Your First Card", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(height: 52)
                    .frame(maxWidth: 260)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: "D4AF37"))
                    )
            }
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Credit Card Widget (Apple Wallet style)
struct CreditCardWidget: View {
    let card: CreditCard
    var width: CGFloat = 300
    var height: CGFloat = 180
    
    var body: some View {
        ZStack {
            // Card background — use card image if available, else gradient
            if let imageData = card.cardImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                cardGradientBackground
            }
            
            // Subtle overlay for readability
            LinearGradient(
                colors: [Color.black.opacity(0.1), Color.black.opacity(0.4)],
                startPoint: .top, endPoint: .bottom
            )
            
            // Card content
            VStack(alignment: .leading, spacing: 0) {
                // Top row: bank + network
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.bankName.uppercased())
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .kerning(1.5)
                        Text(card.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    NetworkLogoView(network: card.network, size: 32)
                }
                
                Spacer()
                
                // Middle: chip symbol
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "D4AF37").opacity(0.8))
                        .frame(width: 34, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(Color(hex: "D4AF37").opacity(0.4), lineWidth: 0.5)
                                .padding(4)
                        )
                    
                    Spacer()
                    
                    // Contactless icon
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Bottom: outstanding + limit
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Outstanding")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("₹\(card.currentOutstanding, format: .number.precision(.fractionLength(0)))")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Due \(dueDateLabel)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(card.daysUntilDue <= 0 ? "Overdue" : "\(card.daysUntilDue) days")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(dueColor)
                    }
                }
            }
            .padding(18)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }
    
    var cardGradientBackground: some View {
        LinearGradient(
            colors: [card.cardColor, card.cardColor.opacity(0.7), card.accentColor.opacity(0.4)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(
            // Subtle pattern
            GeometryReader { geo in
                Circle()
                    .fill(card.accentColor.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width * 0.5, y: -60)
                    .blur(radius: 30)
            }
        )
    }
    
    var dueDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: card.nextDueDate)
    }
    
    var dueColor: Color {
        if card.daysUntilDue <= 0 { return .red }
        if card.daysUntilDue <= 3 { return Color(hex: "FF3B30") }
        if card.daysUntilDue <= 7 { return Color(hex: "FF9500") }
        return .white
    }
}

// MARK: - Card List Row
struct CardListRowView: View {
    let card: CreditCard
    
    var body: some View {
        HStack(spacing: 14) {
            // Mini card preview
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [card.cardColor, card.accentColor.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 34)
                
                NetworkLogoView(network: card.network, size: 16)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(card.name)
                    .font(.system(size: 15, weight: .semibold))
                Text(card.bankName)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("₹\(card.currentOutstanding, format: .number.precision(.fractionLength(0)))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text("\(card.utilizationPercent, format: .number.precision(.fractionLength(0)))% used")
                    .font(.system(size: 11))
                    .foregroundStyle(utilizationColor)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var utilizationColor: Color {
        if card.utilizationPercent < 30 { return Color(hex: "34C759") }
        if card.utilizationPercent < 60 { return Color(hex: "FF9500") }
        return Color(hex: "FF3B30")
    }
}

// MARK: - Network Logo View
struct NetworkLogoView: View {
    let network: CardNetwork
    let size: CGFloat
    
    var body: some View {
        switch network {
        case .visa:
            Text("VISA")
                .font(.system(size: size * 0.4, weight: .black, design: .default))
                .italic()
                .foregroundStyle(.white)
                .frame(width: size, height: size * 0.6)
            
        case .mastercard:
            HStack(spacing: -size * 0.2) {
                Circle()
                    .fill(Color(hex: "EB001B"))
                    .frame(width: size * 0.55)
                Circle()
                    .fill(Color(hex: "F79E1B"))
                    .frame(width: size * 0.55)
            }
            .frame(width: size, height: size * 0.6)
            
        case .amex:
            Text("AMEX")
                .font(.system(size: size * 0.3, weight: .black))
                .foregroundStyle(Color(hex: "007BC1"))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.9))
                )
            
        case .rupay:
            Text("RuPay")
                .font(.system(size: size * 0.32, weight: .bold))
                .foregroundStyle(Color(hex: "009A44"))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.9))
                )
        }
    }
}

// MARK: - Card Detail View
struct CardDetailView: View {
    @Bindable var card: CreditCard
    @Query var allTransactions: [Transaction]
    @State private var showEditCard = false
    @State private var selectedTab = 0
    @Environment(\.modelContext) var context
    
    var cardTransactions: [Transaction] {
        allTransactions.filter { $0.cardID == card.id }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Full-size card
                CreditCardWidget(card: card, width: UIScreen.main.bounds.width - 40, height: 220)
                    .padding(.horizontal, 20)
                
                // Details grid
                cardDetailsGrid
                
                // Reward balance
                rewardBalanceSection
                
                // Quick actions
                quickActionsRow
                
                // Transactions picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transactions")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.horizontal, 20)
                    
                    if cardTransactions.isEmpty {
                        Text("No transactions yet")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(cardTransactions.prefix(10)) { txn in
                                TransactionRowView(transaction: txn)
                                    .background(Color(.secondarySystemBackground))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEditCard = true }
                    .tint(Color(hex: "D4AF37"))
            }
        }
        .sheet(isPresented: $showEditCard) {
            AddCardView(editingCard: card)
        }
    }
    
    var cardDetailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            detailCell("Credit Limit", "₹\(card.creditLimit, format: .number.precision(.fractionLength(0)))", "creditcard", Color(hex: "0A84FF"))
            detailCell("Outstanding", "₹\(card.currentOutstanding, format: .number.precision(.fractionLength(0)))", "minus.circle", Color(hex: "FF3B30"))
            detailCell("Available", "₹\(card.availableLimit, format: .number.precision(.fractionLength(0)))", "checkmark.circle", Color(hex: "30D158"))
            detailCell("Utilisation", "\(card.utilizationPercent, format: .number.precision(.fractionLength(1)))%", "chart.bar", utilizationColor)
            detailCell("Billing Date", "\(card.billingDate) of month", "calendar", Color(hex: "FF9500"))
            detailCell("Due In", "\(max(card.daysUntilDue, 0)) days", "clock", dueColor)
        }
        .padding(.horizontal, 20)
    }
    
    func detailCell(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var rewardBalanceSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reward Balance")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: card.rewardType.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "D4AF37"))
                    Text(rewardDisplay)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                }
            }
            Spacer()
            
            Button("Add Manually") {
                // Could present manual reward adjustment sheet
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(hex: "D4AF37"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(hex: "D4AF37").opacity(0.12))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 20)
    }
    
    var rewardDisplay: String {
        switch card.rewardType {
        case .cashback: return "₹\(card.rewardBalance, format: .number.precision(.fractionLength(2)))"
        case .points: return "\(Int(card.rewardBalance)) pts"
        case .miles: return "\(Int(card.rewardBalance)) miles"
        }
    }
    
    var quickActionsRow: some View {
        HStack(spacing: 12) {
            NavigationLink {
                SmartSuggestionView()
            } label: {
                quickAction("Best For", "wand.and.stars", Color(hex: "D4AF37"))
            }
            .buttonStyle(.plain)
            
            NavigationLink {
                CardMilestonesView(card: card)
            } label: {
                quickAction("Milestones", "trophy.fill", Color(hex: "30D158"))
            }
            .buttonStyle(.plain)
            
            quickAction("Pay Now", "arrow.up.circle.fill", Color(hex: "0A84FF"))
        }
        .padding(.horizontal, 20)
    }
    
    func quickAction(_ title: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var utilizationColor: Color {
        if card.utilizationPercent < 30 { return Color(hex: "34C759") }
        if card.utilizationPercent < 60 { return Color(hex: "FF9500") }
        return Color(hex: "FF3B30")
    }
    
    var dueColor: Color {
        if card.daysUntilDue <= 0 { return .red }
        if card.daysUntilDue <= 3 { return Color(hex: "FF3B30") }
        if card.daysUntilDue <= 7 { return Color(hex: "FF9500") }
        return Color(hex: "30D158")
    }
}
