import SwiftUI
import SwiftData
import PhotosUI

struct AddCardView: View {
    var editingCard: CreditCard? = nil
    
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    
    // Form fields
    @State private var cardName = ""
    @State private var bankName = ""
    @State private var network: CardNetwork = .visa
    @State private var creditLimit = ""
    @State private var outstanding = ""
    @State private var billingDate = 1
    @State private var dueDate = 20
    @State private var rewardType: RewardType = .points
    @State private var rewardBalance = ""
    
    // Reward rates
    @State private var baseRate = "2"
    @State private var diningRate = "10"
    @State private var groceryRate = "5"
    @State private var travelRate = "5"
    @State private var shoppingRate = "5"
    @State private var upiRate = "1"
    
    // Card image & color
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cardImageData: Data?
    @State private var cardColorHex = "1C1C1E"
    @State private var accentColorHex = "D4AF37"
    @State private var cardColor = Color(hex: "1C1C1E")
    @State private var accentColor = Color(hex: "D4AF37")
    
    // UI state
    @State private var currentStep = 1
    @State private var showColorPicker = false
    
    let totalSteps = 3
    
    // Known bank presets
    let bankPresets: [(name: String, color: String, accent: String)] = [
        ("HDFC Bank", "3D2B1F", "D4AF37"),
        ("American Express", "B8960A", "F5D87A"),
        ("Federal Bank", "0D0D0D", "C9A84C"),
        ("ICICI Bank", "8B0000", "E8A700"),
        ("SBI Card", "002244", "FFD700"),
        ("Axis Bank", "800000", "D4AF37"),
        ("Kotak Bank", "CC0000", "FFD700"),
        ("HDFC Bank", "1C1C1E", "D4AF37"),
        ("IndusInd Bank", "003580", "C6A84B"),
        ("Yes Bank", "00205B", "0066CC"),
    ]
    
    var isEditing: Bool { editingCard != nil }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Step indicator
                    stepIndicator
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    
                    // Step content
                    ScrollView {
                        VStack(spacing: 20) {
                            if currentStep == 1 { step1CardInfo }
                            if currentStep == 2 { step2CardDesign }
                            if currentStep == 3 { step3RewardRates }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                }
                
                // Bottom action buttons
                VStack {
                    Spacer()
                    bottomButtons
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear { loadEditingCard() }
            .onChange(of: selectedPhoto) { _, newItem in
                Task { await loadCardImage(from: newItem) }
            }
            .onChange(of: cardColor) { _, new in
                cardColorHex = UIColor(new).toHexString()
            }
            .onChange(of: accentColor) { _, new in
                accentColorHex = UIColor(new).toHexString()
            }
        }
    }
    
    // MARK: - Step Indicator
    var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(step <= currentStep ? Color(hex: "D4AF37") : Color(.tertiarySystemBackground))
                            .frame(width: 28, height: 28)
                        if step < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.black)
                        } else {
                            Text("\(step)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(step == currentStep ? .black : .secondary)
                        }
                    }
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? Color(hex: "D4AF37") : Color(.tertiarySystemBackground))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 1: Card Info
    var step1CardInfo: some View {
        VStack(spacing: 16) {
            sectionHeader("Card Information")
            
            formGroup {
                formField("Card Name", text: $cardName, placeholder: "e.g. Regalia Gold")
                Divider().padding(.leading, 16)
                formField("Bank Name", text: $bankName, placeholder: "e.g. HDFC Bank")
            }
            
            // Bank quick presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Presets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(bankPresets, id: \.name) { preset in
                            Button {
                                bankName = preset.name
                                cardColorHex = preset.color
                                accentColorHex = preset.accent
                                cardColor = Color(hex: preset.color)
                                accentColor = Color(hex: preset.accent)
                            } label: {
                                Text(preset.name.replacingOccurrences(of: " Bank", with: "").replacingOccurrences(of: " Card", with: ""))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(bankName == preset.name ? .black : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(bankName == preset.name ? Color(hex: "D4AF37") : Color(.tertiarySystemBackground))
                                    )
                            }
                        }
                    }
                }
            }
            
            // Network selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Network")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ForEach(CardNetwork.allCases, id: \.self) { n in
                        Button {
                            network = n
                        } label: {
                            VStack(spacing: 6) {
                                NetworkLogoView(network: n, size: 28)
                                    .frame(height: 20)
                                Text(n.rawValue)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(network == n ? Color(hex: "D4AF37") : .secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(network == n ? Color(hex: "D4AF37").opacity(0.1) : Color(.tertiarySystemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(network == n ? Color(hex: "D4AF37") : .clear, lineWidth: 1.5)
                                    )
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            // Financial details
            sectionHeader("Financials")
            
            formGroup {
                formField("Credit Limit (₹)", text: $creditLimit, placeholder: "500000", keyboardType: .numberPad)
                Divider().padding(.leading, 16)
                formField("Current Outstanding (₹)", text: $outstanding, placeholder: "0", keyboardType: .numberPad)
            }
            
            // Dates
            formGroup {
                HStack {
                    Text("Billing Date")
                        .font(.system(size: 15))
                    Spacer()
                    Picker("", selection: $billingDate) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 80)
                    .clipped()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Divider().padding(.leading, 16)
                
                HStack {
                    Text("Days to Due Date")
                        .font(.system(size: 15))
                    Spacer()
                    Picker("", selection: $dueDate) {
                        ForEach([15, 18, 20, 21, 25, 30], id: \.self) { day in
                            Text("\(day) days").tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(hex: "D4AF37"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            // Reward type
            sectionHeader("Rewards")
            
            formGroup {
                HStack {
                    Text("Reward Type")
                        .font(.system(size: 15))
                    Spacer()
                    Picker("", selection: $rewardType) {
                        ForEach(RewardType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(hex: "D4AF37"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider().padding(.leading, 16)
                
                formField("Current Reward Balance", text: $rewardBalance,
                           placeholder: rewardType == .cashback ? "0.00 (₹)" : "0 (pts/miles)",
                           keyboardType: .decimalPad)
            }
        }
    }
    
    // MARK: - Step 2: Card Design
    var step2CardDesign: some View {
        VStack(spacing: 16) {
            sectionHeader("Card Appearance")
            
            // Live preview
            CreditCardWidget(card: previewCard, width: UIScreen.main.bounds.width - 40, height: 200)
            
            // Card image upload
            VStack(alignment: .leading, spacing: 8) {
                Text("Upload Card Image (Optional)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: cardImageData != nil ? "checkmark.circle.fill" : "photo.badge.plus")
                            .foregroundStyle(cardImageData != nil ? Color(hex: "30D158") : Color(hex: "D4AF37"))
                        Text(cardImageData != nil ? "Image Selected" : "Choose Card Image")
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        if cardImageData != nil {
                            Button {
                                cardImageData = nil
                                selectedPhoto = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
                
                Text("Upload a photo of your actual card for realistic preview")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            
            // Colors
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Colors")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Background")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $cardColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(height: 44)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Accent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $accentColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(height: 44)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Color presets based on known cards
                Text("Preset Themes")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                
                let themes: [(String, String, String)] = [
                    ("Regalia Gold", "3D2B1F", "D4AF37"),
                    ("Amex Gold", "B8960A", "F5D87A"),
                    ("Celesta Dark", "0D0D0D", "C9A84C"),
                    ("Sapphiro", "0A2040", "30D0D0"),
                    ("SBI Prime", "002244", "FFD700"),
                    ("Axis Magnus", "4A0010", "FF6B6B"),
                ]
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(themes, id: \.0) { theme in
                        Button {
                            cardColorHex = theme.1
                            accentColorHex = theme.2
                            cardColor = Color(hex: theme.1)
                            accentColor = Color(hex: theme.2)
                        } label: {
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: theme.1))
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color(hex: theme.2), lineWidth: 1.5)
                                    )
                                Text(theme.0)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Reward Rates
    var step3RewardRates: some View {
        VStack(spacing: 16) {
            sectionHeader("Reward Earn Rates")
            
            let rateLabel = rewardType == .cashback ? "% per ₹100" : "pts per ₹100"
            
            Text("Configure how much you earn per category. Check your card's T&C for exact rates.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            formGroup {
                rateRow("Base Rate", "All spends", rateLabel: rateLabel, value: $baseRate, icon: "creditcard", color: .secondary)
                Divider().padding(.leading, 56)
                rateRow("Dining", "Restaurants, food delivery", rateLabel: rateLabel, value: $diningRate, icon: "fork.knife", color: SpendCategory.dining.color)
                Divider().padding(.leading, 56)
                rateRow("Grocery", "Supermarkets, BigBasket", rateLabel: rateLabel, value: $groceryRate, icon: "cart.fill", color: SpendCategory.grocery.color)
                Divider().padding(.leading, 56)
                rateRow("Travel", "Flights, hotels, cabs", rateLabel: rateLabel, value: $travelRate, icon: "airplane", color: SpendCategory.travel.color)
                Divider().padding(.leading, 56)
                rateRow("Shopping", "Amazon, Flipkart, Myntra", rateLabel: rateLabel, value: $shoppingRate, icon: "bag.fill", color: SpendCategory.shopping.color)
                Divider().padding(.leading, 56)
                rateRow("UPI", "UPI transfers", rateLabel: rateLabel, value: $upiRate, icon: "indianrupeesign.circle", color: SpendCategory.upi.color)
            }
        }
    }
    
    func rateRow(_ label: String, _ sub: String, rateLabel: String, value: Binding<String>, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                TextField("0", text: value)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(rateLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Bottom Buttons
    var bottomButtons: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if currentStep > 1 {
                    Button {
                        withAnimation { currentStep -= 1 }
                    } label: {
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                }
                
                Button {
                    if currentStep < totalSteps {
                        withAnimation { currentStep += 1 }
                    } else {
                        saveCard()
                    }
                } label: {
                    Text(currentStep < totalSteps ? "Continue" : (isEditing ? "Save Changes" : "Add Card"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "D4AF37"))
                        )
                }
                .disabled(!canProceed)
                .opacity(canProceed ? 1 : 0.5)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
    }
    
    var canProceed: Bool {
        if currentStep == 1 {
            return !cardName.isEmpty && !bankName.isEmpty && !(creditLimit.isEmpty)
        }
        return true
    }
    
    // MARK: - Helpers
    var previewCard: CreditCard {
        let c = CreditCard(
            name: cardName.isEmpty ? "Card Name" : cardName,
            bankName: bankName.isEmpty ? "Bank" : bankName,
            network: network,
            creditLimit: Double(creditLimit) ?? 500000,
            currentOutstanding: Double(outstanding) ?? 0,
            billingDate: billingDate,
            dueDate: dueDate,
            rewardType: rewardType,
            rewardBalance: Double(rewardBalance) ?? 0,
            cardColorHex: cardColorHex,
            accentColorHex: accentColorHex
        )
        c.cardImageData = cardImageData
        return c
    }
    
    @ViewBuilder
    func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(0.5)
            Spacer()
        }
    }
    
    func formGroup<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }
    
    func formField(_ label: String, text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 200)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    func loadEditingCard() {
        guard let card = editingCard else { return }
        cardName = card.name
        bankName = card.bankName
        network = card.network
        creditLimit = "\(Int(card.creditLimit))"
        outstanding = "\(Int(card.currentOutstanding))"
        billingDate = card.billingDate
        dueDate = card.dueDate
        rewardType = card.rewardType
        rewardBalance = "\(card.rewardBalance)"
        cardColorHex = card.cardColorHex
        accentColorHex = card.accentColorHex
        cardImageData = card.cardImageData
        cardColor = Color(hex: card.cardColorHex)
        accentColor = Color(hex: card.accentColorHex)
        baseRate = "\(card.rewardRateBase)"
        diningRate = "\(card.rewardRateDining)"
        groceryRate = "\(card.rewardRateGrocery)"
        travelRate = "\(card.rewardRateTravel)"
        shoppingRate = "\(card.rewardRateShopping)"
        upiRate = "\(card.rewardRateUPI)"
    }
    
    func saveCard() {
        if let existingCard = editingCard {
            existingCard.name = cardName
            existingCard.bankName = bankName
            existingCard.network = network
            existingCard.creditLimit = Double(creditLimit) ?? existingCard.creditLimit
            existingCard.currentOutstanding = Double(outstanding) ?? existingCard.currentOutstanding
            existingCard.billingDate = billingDate
            existingCard.dueDate = dueDate
            existingCard.rewardType = rewardType
            existingCard.rewardBalance = Double(rewardBalance) ?? existingCard.rewardBalance
            existingCard.cardColorHex = cardColorHex
            existingCard.accentColorHex = accentColorHex
            existingCard.cardImageData = cardImageData
            existingCard.rewardRateBase = Double(baseRate) ?? 2
            existingCard.rewardRateDining = Double(diningRate) ?? 10
            existingCard.rewardRateGrocery = Double(groceryRate) ?? 5
            existingCard.rewardRateTravel = Double(travelRate) ?? 5
            existingCard.rewardRateShopping = Double(shoppingRate) ?? 5
            existingCard.rewardRateUPI = Double(upiRate) ?? 1
        } else {
            let newCard = CreditCard(
                name: cardName, bankName: bankName, network: network,
                creditLimit: Double(creditLimit) ?? 500000,
                currentOutstanding: Double(outstanding) ?? 0,
                billingDate: billingDate, dueDate: dueDate,
                rewardType: rewardType,
                rewardBalance: Double(rewardBalance) ?? 0,
                cardColorHex: cardColorHex, accentColorHex: accentColorHex
            )
            newCard.cardImageData = cardImageData
            newCard.rewardRateBase = Double(baseRate) ?? 2
            newCard.rewardRateDining = Double(diningRate) ?? 10
            newCard.rewardRateGrocery = Double(groceryRate) ?? 5
            newCard.rewardRateTravel = Double(travelRate) ?? 5
            newCard.rewardRateShopping = Double(shoppingRate) ?? 5
            newCard.rewardRateUPI = Double(upiRate) ?? 1
            context.insert(newCard)
        }
        
        try? context.save()
        dismiss()
    }
    
    @MainActor
    func loadCardImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            cardImageData = data
            // Extract dominant color from image
            if let uiImage = UIImage(data: data),
               let dominantColor = extractDominantColor(from: uiImage) {
                cardColor = dominantColor
                cardColorHex = UIColor(dominantColor).toHexString()
            }
        }
    }
    
    func extractDominantColor(from image: UIImage) -> Color? {
        guard let cgImage = image.cgImage else { return nil }
        let width = 50
        let height = 50
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let context = CGContext(
            data: &rawData, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalR: Float = 0, totalG: Float = 0, totalB: Float = 0
        let pixelCount = width * height
        
        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
            totalR += Float(rawData[i])
            totalG += Float(rawData[i + 1])
            totalB += Float(rawData[i + 2])
        }
        
        return Color(
            red: Double(totalR / Float(pixelCount)) / 255.0,
            green: Double(totalG / Float(pixelCount)) / 255.0,
            blue: Double(totalB / Float(pixelCount)) / 255.0
        )
    }
}

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
