import SwiftUI
import SwiftData
import Foundation

// MARK: - Card Network
enum CardNetwork: String, Codable, CaseIterable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case amex = "American Express"
    case rupay = "RuPay"
    
    var logoSystemName: String {
        switch self {
        case .visa: return "visa_logo"
        case .mastercard: return "mastercard_logo"
        case .amex: return "amex_logo"
        case .rupay: return "rupay_logo"
        }
    }
    
    var displayColor: Color {
        switch self {
        case .visa: return Color(hex: "1A1F71")
        case .mastercard: return Color(hex: "EB001B")
        case .amex: return Color(hex: "007BC1")
        case .rupay: return Color(hex: "007BC1")
        }
    }
}

// MARK: - Reward Type
enum RewardType: String, Codable, CaseIterable {
    case points = "Points"
    case cashback = "Cashback"
    case miles = "Miles"
    
    var icon: String {
        switch self {
        case .points: return "star.fill"
        case .cashback: return "indianrupeesign.circle.fill"
        case .miles: return "airplane"
        }
    }
}

// MARK: - Spend Category
enum SpendCategory: String, Codable, CaseIterable {
    case dining = "Dining"
    case grocery = "Grocery"
    case travel = "Travel"
    case utilities = "Utilities"
    case fuel = "Fuel"
    case shopping = "Shopping"
    case upi = "UPI"
    case entertainment = "Entertainment"
    case medical = "Medical"
    case education = "Education"
    case others = "Others"
    
    var icon: String {
        switch self {
        case .dining: return "fork.knife"
        case .grocery: return "cart.fill"
        case .travel: return "airplane"
        case .utilities: return "bolt.fill"
        case .fuel: return "fuelpump.fill"
        case .shopping: return "bag.fill"
        case .upi: return "indianrupeesign.circle.fill"
        case .entertainment: return "film.fill"
        case .medical: return "cross.fill"
        case .education: return "book.fill"
        case .others: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .dining: return Color(hex: "FF6B6B")
        case .grocery: return Color(hex: "51CF66")
        case .travel: return Color(hex: "339AF0")
        case .utilities: return Color(hex: "F59F00")
        case .fuel: return Color(hex: "FF922B")
        case .shopping: return Color(hex: "CC5DE8")
        case .upi: return Color(hex: "20C997")
        case .entertainment: return Color(hex: "F06595")
        case .medical: return Color(hex: "FF4757")
        case .education: return Color(hex: "5C7CFA")
        case .others: return Color(hex: "868E96")
        }
    }
}

// MARK: - Credit Card Model
@Model
final class CreditCard {
    var id: UUID
    var name: String
    var bankName: String
    var network: CardNetwork
    var creditLimit: Double
    var currentOutstanding: Double
    var billingDate: Int  // Day of month 1-31
    var dueDate: Int      // Days after billing date
    var rewardType: RewardType
    var rewardBalance: Double
    var cardImageData: Data?
    var cardColorHex: String
    var accentColorHex: String
    var createdAt: Date
    
    // Reward rates per category (points / cashback % per ₹100)
    var rewardRateBase: Double
    var rewardRateDining: Double
    var rewardRateGrocery: Double
    var rewardRateTravel: Double
    var rewardRateFuel: Double
    var rewardRateShopping: Double
    var rewardRateUPI: Double
    var rewardRateOnline: Double
    
    @Relationship(deleteRule: .cascade) var transactions: [Transaction]
    @Relationship(deleteRule: .cascade) var categories: [CardCategory]
    @Relationship(deleteRule: .cascade) var rewardBalances: [RewardBalance]
    
    var availableLimit: Double { creditLimit - currentOutstanding }
    var utilizationPercent: Double { (currentOutstanding / creditLimit) * 100 }
    
    var nextBillingDate: Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: Date())
        comps.day = billingDate
        let thisMonth = cal.date(from: comps) ?? Date()
        if thisMonth < Date() {
            return cal.date(byAdding: .month, value: 1, to: thisMonth) ?? thisMonth
        }
        return thisMonth
    }
    
    var nextDueDate: Date {
        Calendar.current.date(byAdding: .day, value: dueDate, to: nextBillingDate) ?? nextBillingDate
    }
    
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
    }
    
    var cardColor: Color { Color(hex: cardColorHex) }
    var accentColor: Color { Color(hex: accentColorHex) }
    
    init(name: String, bankName: String, network: CardNetwork, creditLimit: Double,
         currentOutstanding: Double, billingDate: Int, dueDate: Int,
         rewardType: RewardType, rewardBalance: Double = 0,
         cardColorHex: String = "1C1C1E", accentColorHex: String = "D4AF37") {
        self.id = UUID()
        self.name = name
        self.bankName = bankName
        self.network = network
        self.creditLimit = creditLimit
        self.currentOutstanding = currentOutstanding
        self.billingDate = billingDate
        self.dueDate = dueDate
        self.rewardType = rewardType
        self.rewardBalance = rewardBalance
        self.cardColorHex = cardColorHex
        self.accentColorHex = accentColorHex
        self.createdAt = Date()
        self.rewardRateBase = rewardType == .cashback ? 0.5 : 2.0
        self.rewardRateDining = rewardType == .cashback ? 2.0 : 10.0
        self.rewardRateGrocery = rewardType == .cashback ? 1.0 : 5.0
        self.rewardRateTravel = rewardType == .cashback ? 1.0 : 5.0
        self.rewardRateFuel = 0.0
        self.rewardRateShopping = rewardType == .cashback ? 1.0 : 5.0
        self.rewardRateUPI = rewardType == .cashback ? 0.25 : 1.0
        self.rewardRateOnline = rewardType == .cashback ? 2.0 : 10.0
        self.transactions = []
        self.categories = []
        self.rewardBalances = []
    }
    
    func rewardRate(for category: SpendCategory) -> Double {
        switch category {
        case .dining: return rewardRateDining
        case .grocery: return rewardRateGrocery
        case .travel: return rewardRateTravel
        case .fuel: return rewardRateFuel
        case .shopping, .entertainment: return rewardRateShopping
        case .upi: return rewardRateUPI
        default: return rewardRateBase
        }
    }
}

// MARK: - Transaction Model
@Model
final class Transaction {
    var id: UUID
    var cardID: UUID
    var amount: Double
    var merchant: String
    var category: SpendCategory
    var date: Date
    var rawSMS: String?
    var rewardsEarned: Double
    var isCancelled: Bool
    var isRefunded: Bool
    var note: String?
    
    init(cardID: UUID, amount: Double, merchant: String, category: SpendCategory,
         date: Date = Date(), rawSMS: String? = nil, rewardsEarned: Double = 0) {
        self.id = UUID()
        self.cardID = cardID
        self.amount = amount
        self.merchant = merchant
        self.category = category
        self.date = date
        self.rawSMS = rawSMS
        self.rewardsEarned = rewardsEarned
        self.isCancelled = false
        self.isRefunded = false
    }
}

// MARK: - Offer Model
@Model
final class Offer {
    var id: UUID
    var title: String
    var bankName: String
    var merchantName: String
    var discountDescription: String
    var validityEnd: Date
    var eligibleCardIDs: [UUID]
    var isActive: Bool
    var category: SpendCategory
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: validityEnd).day ?? 0
    }
    
    var isExpired: Bool { validityEnd < Date() }
    
    init(title: String, bankName: String, merchantName: String, discountDescription: String,
         validityEnd: Date, eligibleCardIDs: [UUID] = [], category: SpendCategory = .others) {
        self.id = UUID()
        self.title = title
        self.bankName = bankName
        self.merchantName = merchantName
        self.discountDescription = discountDescription
        self.validityEnd = validityEnd
        self.eligibleCardIDs = eligibleCardIDs
        self.isActive = true
        self.category = category
    }
}

// MARK: - Card Category (Smart Suggestion)
@Model
final class CardCategory {
    var id: UUID
    var cardID: UUID
    var categoryName: String
    var merchantNames: [String]
    var apps: [String]
    var websites: [String]
    var rewardMultiplier: Double
    
    init(cardID: UUID, categoryName: String, merchantNames: [String] = [],
         apps: [String] = [], websites: [String] = [], rewardMultiplier: Double = 1.0) {
        self.id = UUID()
        self.cardID = cardID
        self.categoryName = categoryName
        self.merchantNames = merchantNames
        self.apps = apps
        self.websites = websites
        self.rewardMultiplier = rewardMultiplier
    }
}

// MARK: - Reward Balance History
@Model
final class RewardBalance {
    var id: UUID
    var cardID: UUID
    var balance: Double
    var date: Date
    var description: String
    
    init(cardID: UUID, balance: Double, description: String) {
        self.id = UUID()
        self.cardID = cardID
        self.balance = balance
        self.date = Date()
        self.description = description
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uic.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
