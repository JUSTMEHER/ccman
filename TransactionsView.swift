import SwiftUI
import SwiftData
import MessageUI

// MARK: - Transactions View
struct TransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]
    @Query var cards: [CreditCard]
    @Environment(\.modelContext) var context
    
    @State private var searchText = ""
    @State private var selectedCategory: SpendCategory? = nil
    @State private var showAddTransaction = false
    @State private var showSMSImport = false
    @State private var selectedCard: CreditCard? = nil
    
    var filtered: [Transaction] {
        var result = transactions
        if !searchText.isEmpty {
            result = result.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if let card = selectedCard {
            result = result.filter { $0.cardID == card.id }
        }
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterBar
                
                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedTransactions, id: \.key) { group in
                            Section(group.key) {
                                ForEach(group.value) { txn in
                                    TransactionRowView(transaction: txn)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                deleteTransaction(txn)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            
                                            Button {
                                                toggleCancelled(txn)
                                            } label: {
                                                Label(txn.isCancelled ? "Restore" : "Cancel", systemImage: txn.isCancelled ? "arrow.uturn.left" : "xmark.circle")
                                            }
                                            .tint(Color(hex: "FF9500"))
                                        }
                                }
                            }
                            .listSectionSeparator(.hidden)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Spends")
            .searchable(text: $searchText, prompt: "Search merchants...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showAddTransaction = true
                        } label: {
                            Label("Add Manually", systemImage: "plus.circle")
                        }
                        Button {
                            showSMSImport = true
                        } label: {
                            Label("Import from SMS", systemImage: "message.badge.filled.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .tint(Color(hex: "D4AF37"))
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showSMSImport) {
                SMSImportView()
            }
        }
    }
    
    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip("All", isSelected: selectedCategory == nil && selectedCard == nil) {
                    selectedCategory = nil
                    selectedCard = nil
                }
                
                ForEach(cards.prefix(3)) { card in
                    FilterChip(card.name, isSelected: selectedCard?.id == card.id) {
                        selectedCard = selectedCard?.id == card.id ? nil : card
                    }
                }
                
                Divider().frame(height: 20)
                
                ForEach(SpendCategory.allCases, id: \.self) { cat in
                    FilterChip(cat.rawValue, icon: cat.icon, color: cat.color,
                               isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    var groupedTransactions: [(key: String, value: [Transaction])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        
        let grouped = Dictionary(grouping: filtered) { txn -> String in
            if calendar.isDateInToday(txn.date) { return "Today" }
            if calendar.isDateInYesterday(txn.date) { return "Yesterday" }
            return formatter.string(from: txn.date)
        }
        
        return grouped.sorted { a, b in
            if a.key == "Today" { return true }
            if b.key == "Today" { return false }
            if a.key == "Yesterday" { return true }
            if b.key == "Yesterday" { return false }
            return a.key > b.key
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.tertiary)
            Text("No Transactions")
                .font(.system(size: 18, weight: .semibold))
            Text("Import from SMS or add manually")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    func deleteTransaction(_ txn: Transaction) {
        // Reverse rewards
        if let card = cards.first(where: { $0.id == txn.cardID }) {
            var mutableCard = card
            RewardsEngine.shared.reverseRewards(transaction: txn, card: &mutableCard)
        }
        context.delete(txn)
        try? context.save()
    }
    
    func toggleCancelled(_ txn: Transaction) {
        if let card = cards.first(where: { $0.id == txn.cardID }) {
            var mutableCard = card
            if !txn.isCancelled {
                // Cancel: remove rewards
                RewardsEngine.shared.reverseRewards(transaction: txn, card: &mutableCard)
                txn.isCancelled = true
            } else {
                // Restore: re-add rewards
                let rewards = RewardsEngine.shared.calculateRewards(
                    amount: txn.amount, category: txn.category, card: card)
                mutableCard.rewardBalance += rewards
                txn.isCancelled = false
            }
        }
        try? context.save()
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    var icon: String? = nil
    var color: Color = .secondary
    let isSelected: Bool
    let action: () -> Void
    
    init(_ label: String, icon: String? = nil, color: Color = .secondary, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? (icon != nil ? color : Color.primary) : Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transaction Row
struct TransactionRowView: View {
    let transaction: Transaction
    @Query var cards: [CreditCard]
    
    var card: CreditCard? { cards.first { $0.id == transaction.cardID } }
    
    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(transaction.isCancelled ? 0.06 : 0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(transaction.category.color.opacity(transaction.isCancelled ? 0.4 : 1))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(transaction.merchant)
                        .font(.system(size: 15, weight: .semibold))
                        .strikethrough(transaction.isCancelled)
                        .foregroundStyle(transaction.isCancelled ? .secondary : .primary)
                    
                    if transaction.isCancelled {
                        Text("Cancelled")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.1)))
                    }
                }
                
                HStack(spacing: 4) {
                    if let card {
                        Text(card.name)
                            .font(.system(size: 12))
                            .foregroundStyle(card.accentColor.opacity(0.8))
                    }
                    Text("·")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 12))
                    Text(transaction.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("₹\(transaction.amount, format: .number.precision(.fractionLength(0)))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(transaction.isCancelled ? .secondary : .primary)
                
                if transaction.rewardsEarned > 0 && !transaction.isCancelled {
                    Text("+\(Int(transaction.rewardsEarned)) \(rewardLabel)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "30D158"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    var rewardLabel: String {
        guard let card else { return "pts" }
        switch card.rewardType {
        case .cashback: return "₹ back"
        case .points: return "pts"
        case .miles: return "mi"
        }
    }
}

// MARK: - Add Transaction Manually
struct AddTransactionView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Query var cards: [CreditCard]
    
    @State private var amount = ""
    @State private var merchant = ""
    @State private var selectedCategory: SpendCategory = .shopping
    @State private var selectedCardID: UUID? = nil
    @State private var date = Date()
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    TextField("Amount (₹)", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Merchant / Description", text: $merchant)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SpendCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                
                Section("Card") {
                    ForEach(cards) { card in
                        Button {
                            selectedCardID = card.id
                        } label: {
                            HStack {
                                Text(card.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedCardID == card.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "D4AF37"))
                                }
                            }
                        }
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Add a note...", text: $note)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { saveTransaction() }
                        .fontWeight(.semibold)
                        .tint(Color(hex: "D4AF37"))
                        .disabled(amount.isEmpty || selectedCardID == nil)
                }
            }
            .onAppear {
                if selectedCardID == nil { selectedCardID = cards.first?.id }
            }
        }
    }
    
    func saveTransaction() {
        guard let cardID = selectedCardID,
              let card = cards.first(where: { $0.id == cardID }),
              let amountValue = Double(amount) else { return }
        
        let rewards = RewardsEngine.shared.calculateRewards(
            amount: amountValue, category: selectedCategory, card: card)
        
        let txn = Transaction(cardID: cardID, amount: amountValue,
                               merchant: merchant.isEmpty ? "Manual Entry" : merchant,
                               category: selectedCategory, date: date,
                               rewardsEarned: rewards)
        txn.note = note.isEmpty ? nil : note
        context.insert(txn)
        
        // Update card outstanding and rewards
        card.currentOutstanding += amountValue
        card.rewardBalance += rewards
        
        try? context.save()
        dismiss()
    }
}

// MARK: - SMS Import View
struct SMSImportView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Query var cards: [CreditCard]
    
    @State private var smsText = ""
    @State private var parsed: ParsedTransaction? = nil
    @State private var selectedCardID: UUID? = nil
    @State private var showSuccess = false
    @State private var step = 1
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if step == 1 {
                    pasteStep
                } else if let p = parsed {
                    confirmStep(p)
                }
            }
            .padding(20)
            .navigationTitle("Import SMS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Transaction Added ✓", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
                Button("Add Another") {
                    smsText = ""; parsed = nil; step = 1; selectedCardID = nil
                }
            } message: {
                Text("The transaction has been recorded and rewards updated.")
            }
        }
    }
    
    var pasteStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Paste Bank SMS", systemImage: "message.fill")
                    .font(.system(size: 17, weight: .semibold))
                Text("Copy a transaction SMS from your messages app and paste it below.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            TextEditor(text: $smsText)
                .frame(minHeight: 140)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .font(.system(size: 14, design: .monospaced))
                .overlay(alignment: .topLeading) {
                    if smsText.isEmpty {
                        Text("e.g. INR 2,450.00 spent on HDFC Regalia Gold Card at Amazon on 01-Mar-26. Avail limit: ₹95,000")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
            
            // Sample SMSes for demo
            VStack(alignment: .leading, spacing: 6) {
                Text("Sample Bank SMS Formats")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                ForEach(sampleSMSes, id: \.self) { sample in
                    Button {
                        smsText = sample
                    } label: {
                        Text(sample)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            Button {
                parseSMS()
            } label: {
                Label("Parse SMS", systemImage: "doc.text.magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(smsText.isEmpty ? Color(.systemFill) : Color(hex: "D4AF37"))
                    )
            }
            .disabled(smsText.isEmpty)
        }
    }
    
    @ViewBuilder
    func confirmStep(_ p: ParsedTransaction) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Parsed result
            VStack(alignment: .leading, spacing: 4) {
                Label("Parsed Successfully", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "30D158"))
            }
            
            // Details card
            VStack(spacing: 0) {
                parsedRow("Amount", "₹\(p.amount, format: .number.precision(.fractionLength(2)))")
                Divider()
                parsedRow("Merchant", p.merchant)
                Divider()
                parsedRow("Category", p.category.rawValue)
                Divider()
                parsedRow("Bank Detected", p.bank ?? "Unknown")
                if let last4 = p.cardLast4 {
                    Divider()
                    parsedRow("Card Ending", "•••• \(last4)")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            
            // Assign to card
            VStack(alignment: .leading, spacing: 8) {
                Text("Assign to Card")
                    .font(.system(size: 14, weight: .semibold))
                
                ForEach(cards) { card in
                    Button {
                        selectedCardID = card.id
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(colors: [card.cardColor, card.accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 32, height: 20)
                                NetworkLogoView(network: card.network, size: 12)
                            }
                            Text(card.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedCardID == card.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "D4AF37"))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCardID == card.id ? Color(hex: "D4AF37").opacity(0.08) : Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(selectedCardID == card.id ? Color(hex: "D4AF37") : .clear, lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    step = 1
                } label: {
                    Text("Re-parse")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                }
                .foregroundStyle(.primary)
                
                Button {
                    confirmTransaction(p)
                } label: {
                    Text("Confirm & Add")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedCardID != nil ? Color(hex: "D4AF37") : Color(.systemFill))
                        )
                }
                .disabled(selectedCardID == nil)
            }
        }
    }
    
    func parsedRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    func parseSMS() {
        guard let result = SMSParserService.shared.parse(sms: smsText) else {
            // Show error
            return
        }
        parsed = result
        // Pre-select matched card
        if let matched = SMSParserService.shared.matchCard(parsed: result, cards: cards) {
            selectedCardID = matched.id
        } else {
            selectedCardID = cards.first?.id
        }
        withAnimation { step = 2 }
    }
    
    func confirmTransaction(_ p: ParsedTransaction) {
        guard let cardID = selectedCardID,
              let card = cards.first(where: { $0.id == cardID }) else { return }
        
        let rewards = RewardsEngine.shared.calculateRewards(
            amount: p.amount, category: p.category, card: card)
        
        let txn = Transaction(cardID: cardID, amount: p.amount,
                               merchant: p.merchant, category: p.category,
                               date: p.date, rawSMS: p.rawSMS,
                               rewardsEarned: rewards)
        context.insert(txn)
        
        card.currentOutstanding += p.amount
        card.rewardBalance += rewards
        
        try? context.save()
        showSuccess = true
    }
    
    let sampleSMSes = [
        "INR 2,450.00 spent on HDFC Regalia Gold Card ending 4521 at Amazon on 01-Mar-26. Avail limit: ₹95,000",
        "Rs 8,999 debited from SBI Card PRIME ending 3344 at Croma Electronics on 28-Feb-26. Available credit: Rs 1,41,001",
        "Your Federal Bank Celesta Visa Card XX6777 has been charged INR 1,250 at Swiggy on 01-Mar-2026",
        "AMEX Card ending 7997 - INR 3,500 charged at EazyDiner on 01-Mar-26. MR Points balance: 24,500",
    ]
}
