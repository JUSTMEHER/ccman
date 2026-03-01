import SwiftUI
import SwiftData

// MARK: - Offers View
struct OffersView: View {
    @Query(sort: \Offer.validityEnd) var offers: [Offer]
    @Query var cards: [CreditCard]
    @State private var showAddOffer = false
    @Environment(\.modelContext) var context
    
    var activeOffers: [Offer] { offers.filter { !$0.isExpired && $0.isActive } }
    var expiredOffers: [Offer] { offers.filter { $0.isExpired } }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if activeOffers.isEmpty && expiredOffers.isEmpty {
                        emptyState
                    } else {
                        if !activeOffers.isEmpty {
                            offerSection("Active Offers", offers: activeOffers)
                        }
                        if !expiredOffers.isEmpty {
                            offerSection("Expired", offers: expiredOffers, faded: true)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Offers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddOffer = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .tint(Color(hex: "D4AF37"))
                }
            }
            .sheet(isPresented: $showAddOffer) {
                AddOfferView()
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Image(systemName: "tag.fill")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(Color(hex: "D4AF37").opacity(0.7))
            
            VStack(spacing: 8) {
                Text("No Offers Yet")
                    .font(.system(size: 20, weight: .bold))
                Text("Add bank and merchant offers to track their validity and the best card to use.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showAddOffer = true
            } label: {
                Label("Add First Offer", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(height: 52)
                    .frame(maxWidth: 240)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "D4AF37")))
            }
            Spacer()
        }
    }
    
    func offerSection(_ title: String, offers: [Offer], faded: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(0.5)
            
            ForEach(offers) { offer in
                OfferCardView(offer: offer, cards: cards, faded: faded)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            context.delete(offer)
                            try? context.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
}

struct OfferCardView: View {
    let offer: Offer
    let cards: [CreditCard]
    let faded: Bool
    
    var eligibleCards: [CreditCard] {
        cards.filter { offer.eligibleCardIDs.contains($0.id) }
    }
    
    var urgencyColor: Color {
        if offer.isExpired { return .secondary }
        if offer.daysRemaining <= 3 { return Color(hex: "FF3B30") }
        if offer.daysRemaining <= 7 { return Color(hex: "FF9500") }
        return Color(hex: "30D158")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(offer.merchantName)
                            .font(.system(size: 16, weight: .bold))
                        Text(offer.bankName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(offer.title)
                        .font(.system(size: 14))
                        .foregroundStyle(faded ? .secondary : .primary)
                }
                
                Spacer()
                
                // Expiry badge
                VStack(spacing: 2) {
                    Text(offer.isExpired ? "Expired" : "\(offer.daysRemaining)d left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(urgencyColor)
                    if !offer.isExpired {
                        Text(offer.validityEnd, style: .date)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(urgencyColor.opacity(0.1))
                        .overlay(Capsule().strokeBorder(urgencyColor.opacity(0.3), lineWidth: 1))
                )
            }
            
            // Discount highlight
            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "D4AF37"))
                Text(offer.discountDescription)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(faded ? .secondary : Color(hex: "D4AF37"))
            }
            
            // Eligible cards
            if !eligibleCards.isEmpty {
                HStack(spacing: 6) {
                    Text("Best with:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    ForEach(eligibleCards.prefix(3)) { card in
                        Text(card.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(card.accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(card.accentColor.opacity(0.1))
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .opacity(faded ? 0.6 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    offer.daysRemaining <= 3 && !offer.isExpired ? Color(hex: "FF3B30").opacity(0.3) : .clear,
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Add Offer View
struct AddOfferView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Query var cards: [CreditCard]
    
    @State private var title = ""
    @State private var bankName = ""
    @State private var merchantName = ""
    @State private var discount = ""
    @State private var validityEnd = Date().addingTimeInterval(30 * 86400)
    @State private var selectedCardIDs: Set<UUID> = []
    @State private var category: SpendCategory = .shopping
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Offer Details") {
                    TextField("Title", text: $title, prompt: Text("e.g. 10% off on Swiggy"))
                    TextField("Bank", text: $bankName, prompt: Text("e.g. HDFC Bank"))
                    TextField("Merchant", text: $merchantName, prompt: Text("e.g. Swiggy"))
                    TextField("Discount", text: $discount, prompt: Text("e.g. 10% cashback up to ₹500"))
                    DatePicker("Valid Until", selection: $validityEnd, displayedComponents: .date)
                    Picker("Category", selection: $category) {
                        ForEach(SpendCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                
                Section("Eligible Cards") {
                    ForEach(cards) { card in
                        Button {
                            if selectedCardIDs.contains(card.id) {
                                selectedCardIDs.remove(card.id)
                            } else {
                                selectedCardIDs.insert(card.id)
                            }
                        } label: {
                            HStack {
                                Text(card.name).foregroundStyle(.primary)
                                Spacer()
                                if selectedCardIDs.contains(card.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "D4AF37"))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let offer = Offer(title: title, bankName: bankName, merchantName: merchantName,
                                          discountDescription: discount, validityEnd: validityEnd,
                                          eligibleCardIDs: Array(selectedCardIDs), category: category)
                        context.insert(offer)
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "D4AF37"))
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Smart Suggestion View
struct SmartSuggestionView: View {
    @Query var cards: [CreditCard]
    @State private var merchantQuery = ""
    @State private var selectedCategory: SpendCategory = .shopping
    @State private var amount = ""
    @State private var suggestions: [(card: CreditCard, reward: Double, label: String)] = []
    
    let quickCategories: [(String, SpendCategory, String)] = [
        ("Amazon", .shopping, "amazon"),
        ("Swiggy", .dining, "swiggy"),
        ("Zomato", .dining, "zomato"),
        ("Flipkart", .shopping, "flipkart"),
        ("Fuel", .fuel, ""),
        ("Travel", .travel, ""),
        ("BigBasket", .grocery, "bigbasket"),
        ("Netflix", .entertainment, "netflix"),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Input
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Merchant or category...", text: $merchantQuery)
                                .font(.system(size: 16))
                                .onSubmit { calculate() }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
                        
                        HStack {
                            TextField("Amount (₹)", text: $amount)
                                .keyboardType(.decimalPad)
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                            
                            Button {
                                calculate()
                            } label: {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.black)
                                    .frame(width: 52, height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "D4AF37"))
                                    )
                            }
                        }
                    }
                    
                    // Category picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(SpendCategory.allCases, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                    calculate()
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedCategory == cat ? cat.color : cat.color.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 18))
                                                .foregroundStyle(selectedCategory == cat ? .white : cat.color)
                                        }
                                        Text(cat.rawValue)
                                            .font(.system(size: 11, weight: selectedCategory == cat ? .bold : .medium))
                                            .foregroundStyle(selectedCategory == cat ? .primary : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // Quick presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Presets")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(quickCategories, id: \.0) { item in
                                Button {
                                    merchantQuery = item.0
                                    selectedCategory = item.1
                                    calculate()
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(item.1.color.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: item.1.icon)
                                                .font(.system(size: 18))
                                                .foregroundStyle(item.1.color)
                                        }
                                        Text(item.0)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Results
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Best Cards for \(merchantQuery.isEmpty ? selectedCategory.rawValue : merchantQuery)")
                                .font(.system(size: 16, weight: .bold))
                            
                            ForEach(Array(suggestions.enumerated()), id: \.offset) { idx, suggestion in
                                HStack(spacing: 14) {
                                    // Rank
                                    ZStack {
                                        Circle()
                                            .fill(idx == 0 ? Color(hex: "D4AF37") : Color(.tertiarySystemBackground))
                                            .frame(width: 32, height: 32)
                                        Text("\(idx + 1)")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(idx == 0 ? .black : .secondary)
                                    }
                                    
                                    // Mini card
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(colors: [suggestion.card.cardColor, suggestion.card.accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 44, height: 28)
                                        NetworkLogoView(network: suggestion.card.network, size: 14)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.card.name)
                                            .font(.system(size: 15, weight: .semibold))
                                        Text(suggestion.label)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(rewardDisplay(suggestion.reward, type: suggestion.card.rewardType))
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(idx == 0 ? Color(hex: "D4AF37") : .primary)
                                        Text("earn")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(idx == 0 ? Color(hex: "D4AF37").opacity(0.06) : Color(.secondarySystemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(idx == 0 ? Color(hex: "D4AF37").opacity(0.3) : .clear, lineWidth: 1.5)
                                        )
                                )
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Smart Suggest")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { calculate() }
        }
    }
    
    func calculate() {
        let category: SpendCategory
        if !merchantQuery.isEmpty {
            category = SMSParserService.shared.categorize(merchant: merchantQuery, text: merchantQuery.lowercased())
        } else {
            category = selectedCategory
        }
        
        let amountValue = Double(amount) ?? 10000
        
        suggestions = cards.map { card in
            let rate = card.rewardRate(for: category)
            let reward = RewardsEngine.shared.calculateRewards(amount: amountValue, category: category, card: card)
            let label = "\(rate)\(card.rewardType == .cashback ? "% cashback" : " pts") per ₹100"
            return (card: card, reward: reward, label: label)
        }.sorted { $0.reward > $1.reward }
    }
    
    func rewardDisplay(_ value: Double, type: RewardType) -> String {
        switch type {
        case .cashback: return "₹\(String(format: "%.0f", value))"
        case .points: return "\(Int(value)) pts"
        case .miles: return "\(Int(value)) mi"
        }
    }
}

// MARK: - Card Milestones View
struct CardMilestonesView: View {
    let card: CreditCard
    @Query var transactions: [Transaction]
    
    var cardTransactions: [Transaction] {
        transactions.filter { $0.cardID == card.id && !$0.isCancelled }
    }
    
    var annualSpend: Double { cardTransactions.reduce(0) { $0 + $1.amount } }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Annual spend progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("Annual Spend Progress")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("₹\(annualSpend, format: .number.precision(.fractionLength(0)))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(card.accentColor)
                    
                    Text("tracked this year")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // Reward balance
                VStack(alignment: .leading, spacing: 8) {
                    Label("Total Rewards Earned", systemImage: card.rewardType.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text(RewardsEngine.shared.rewardLabel(card.rewardBalance, type: card.rewardType))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "D4AF37"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // Category breakdown
                categoryBreakdown
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.large)
    }
    
    var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Spend by Category")
                .font(.system(size: 16, weight: .semibold))
            
            let grouped = Dictionary(grouping: cardTransactions) { $0.category }
            let sorted = grouped.sorted { a, b in
                a.value.reduce(0) { $0 + $1.amount } > b.value.reduce(0) { $0 + $1.amount }
            }
            
            let total = cardTransactions.reduce(0.0) { $0 + $1.amount }
            
            ForEach(sorted.prefix(8), id: \.key) { item in
                let catTotal = item.value.reduce(0.0) { $0 + $1.amount }
                let fraction = total > 0 ? catTotal / total : 0
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(item.key.color.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: item.key.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(item.key.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.key.rawValue)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text("₹\(catTotal, format: .number.precision(.fractionLength(0)))")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(item.key.color.opacity(0.1)).frame(height: 4)
                                Capsule().fill(item.key.color)
                                    .frame(width: geo.size.width * fraction, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Query var cards: [CreditCard]
    @Query var transactions: [Transaction]
    @Environment(\.modelContext) var context
    
    @AppStorage("faceIDEnabled") var faceIDEnabled = true
    @State private var showResetAlert = false
    @State private var showExportSheet = false
    @State private var exportCSV = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Security") {
                    Toggle(isOn: $faceIDEnabled) {
                        Label("Face ID / Touch ID", systemImage: "faceid")
                    }
                    .tint(Color(hex: "D4AF37"))
                }
                
                Section("Data") {
                    Button {
                        exportCSV = generateCSV()
                        showExportSheet = true
                    } label: {
                        Label("Export Transactions (CSV)", systemImage: "square.and.arrow.up")
                            .foregroundStyle(.primary)
                    }
                    
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset All Rewards", systemImage: "arrow.counterclockwise.circle")
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Cards", value: "\(cards.count)")
                    LabeledContent("Transactions", value: "\(transactions.count)")
                }
                
                Section("Cards") {
                    ForEach(cards) { card in
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(colors: [card.cardColor, card.accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 36, height: 24)
                                NetworkLogoView(network: card.network, size: 12)
                            }
                            VStack(alignment: .leading) {
                                Text(card.name).font(.system(size: 14, weight: .medium))
                                Text("Due in \(max(card.daysUntilDue, 0)) days").font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(card.annualFee == 0 ? "LTF" : "₹\(Int(card.annualFee))/yr")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet { context.delete(cards[idx]) }
                        try? context.save()
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Rewards?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    for card in cards { card.rewardBalance = 0 }
                    try? context.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will zero out reward balances on all cards. Transactions will remain.")
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(text: exportCSV)
            }
        }
    }
    
    func generateCSV() -> String {
        var csv = "Date,Merchant,Amount,Category,Card,Rewards Earned,Cancelled\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        for txn in transactions.sorted(by: { $0.date > $1.date }) {
            let cardName = cards.first(where: { $0.id == txn.cardID })?.name ?? "Unknown"
            let line = "\(dateFormatter.string(from: txn.date)),\(txn.merchant),\(txn.amount),\(txn.category.rawValue),\(cardName),\(txn.rewardsEarned),\(txn.isCancelled ? "Yes" : "No")"
            csv += line + "\n"
        }
        return csv
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
