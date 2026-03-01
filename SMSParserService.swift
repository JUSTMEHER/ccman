import Foundation
import SwiftData

// MARK: - Parsed SMS Result
struct ParsedTransaction {
    let amount: Double
    let merchant: String
    let cardLast4: String?
    let bank: String?
    let date: Date
    let category: SpendCategory
    let rawSMS: String
}

// MARK: - SMS Parser Service
final class SMSParserService {
    
    static let shared = SMSParserService()
    private init() {}
    
    // MARK: - Indian Bank SMS Patterns
    private let amountPatterns: [String] = [
        #"(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{2})?)"#,
        #"(?:debited|spent|charged|withdrawn)\s+(?:by|with|of|for)?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{2})?)"#,
        #"([\d,]+(?:\.\d{2})?)\s*(?:INR|Rs\.?|₹)"#,
    ]
    
    private let merchantPatterns: [String] = [
        #"(?:at|to|for|from)\s+([A-Za-z0-9\s&'.-]{2,40})(?:\s+on|\s+via|\s+dated|\.|\,|$)"#,
        #"(?:purchase at|txn at|payment to|paid to)\s+([A-Za-z0-9\s&'.-]{2,40})"#,
        #"MERCHANT:\s*([A-Za-z0-9\s&'.-]{2,40})"#,
        #"UPI:([A-Za-z0-9@._-]{4,40})"#,
    ]
    
    private let cardPatterns: [String] = [
        #"(?:card|cc|credit card|a/c).*?(?:no\.?|number|ending|XX+)?\s*([0-9]{4})\b"#,
        #"XX([0-9]{4})\b"#,
        #"ending\s+([0-9]{4})\b"#,
        #"\b([0-9]{4})\s+(?:card|a\/c)\b"#,
    ]
    
    private let bankKeywords: [String: String] = [
        "HDFC": "HDFC Bank",
        "ICICI": "ICICI Bank",
        "SBI": "SBI Card",
        "AXIS": "Axis Bank",
        "KOTAK": "Kotak Bank",
        "AMEX": "American Express",
        "INDUSIND": "IndusInd Bank",
        "FEDERAL": "Federal Bank",
        "HSBC": "HSBC Bank",
        "CITI": "Citibank",
        "IDFC": "IDFC Bank",
        "YES": "Yes Bank",
        "BAJAJ": "Bajaj Finserv",
        "AU": "AU Small Finance",
        "RBL": "RBL Bank",
    ]
    
    // Merchant → Category mapping
    private let merchantCategoryMap: [String: SpendCategory] = [
        // Dining
        "swiggy": .dining, "zomato": .dining, "dominos": .dining, "mcdonalds": .dining,
        "kfc": .dining, "pizza hut": .dining, "subway": .dining, "starbucks": .dining,
        "cafe coffee day": .dining, "ccd": .dining, "barbeque": .dining,
        
        // Grocery
        "bigbasket": .grocery, "grofers": .grocery, "blinkit": .grocery, "zepto": .grocery,
        "dmart": .grocery, "reliance fresh": .grocery, "more supermarket": .grocery,
        "spencers": .grocery, "nature basket": .grocery, "lulu": .grocery,
        
        // Travel
        "makemytrip": .travel, "goibibo": .travel, "cleartrip": .travel, "easemytrip": .travel,
        "irctc": .travel, "ola": .travel, "uber": .travel, "rapido": .travel,
        "air india": .travel, "indigo": .travel, "spicejet": .travel, "vistara": .travel,
        "airasia": .travel, "redbus": .travel, "yatra": .travel,
        
        // Fuel
        "bharat petroleum": .fuel, "bpcl": .fuel, "indian oil": .fuel, "hpcl": .fuel,
        "reliance petrol": .fuel, "nayara": .fuel, "shell": .fuel, "essar": .fuel,
        
        // Shopping
        "amazon": .shopping, "flipkart": .shopping, "myntra": .shopping, "ajio": .shopping,
        "meesho": .shopping, "snapdeal": .shopping, "nykaa": .shopping, "purplle": .shopping,
        "tatacliq": .shopping, "croma": .shopping, "reliance digital": .shopping,
        "vijay sales": .shopping, "samsung": .shopping, "apple": .shopping,
        
        // Entertainment
        "bookmyshow": .entertainment, "pvr": .entertainment, "inox": .entertainment,
        "netflix": .entertainment, "spotify": .entertainment, "hotstar": .entertainment,
        "amazon prime": .entertainment, "sonyliv": .entertainment, "zee5": .entertainment,
        "youtube premium": .entertainment,
        
        // Utilities
        "electricity": .utilities, "bescom": .utilities, "tata power": .utilities,
        "airtel": .utilities, "jio": .utilities, "bsnl": .utilities, "vodafone": .utilities,
        "vi ": .utilities, "act fibernet": .utilities, "hathway": .utilities,
        "piped gas": .utilities, "mahanagar gas": .utilities,
        
        // UPI
        "upi": .upi, "phonepe": .upi, "gpay": .upi, "paytm": .upi,
        "bhim": .upi, "amazon pay": .upi, "mobikwik": .upi,
        
        // Medical
        "apollo": .medical, "practo": .medical, "1mg": .medical, "netmeds": .medical,
        "pharmeasy": .medical, "medplus": .medical, "hospital": .medical, "clinic": .medical,
        
        // Education
        "byju": .education, "unacademy": .education, "coursera": .education,
        "udemy": .education, "udacity": .education, "school": .education, "college": .education,
    ]
    
    // MARK: - Parse Single SMS
    func parse(sms: String) -> ParsedTransaction? {
        let text = sms.lowercased()
        
        // Extract amount
        guard let amount = extractAmount(from: sms) else { return nil }
        
        // Extract merchant
        let merchant = extractMerchant(from: sms) ?? "Unknown Merchant"
        
        // Extract card last 4
        let cardLast4 = extractCardLast4(from: sms)
        
        // Extract bank
        let bank = extractBank(from: sms)
        
        // Extract or infer date
        let date = extractDate(from: sms) ?? Date()
        
        // Categorize
        let category = categorize(merchant: merchant, text: text)
        
        return ParsedTransaction(
            amount: amount,
            merchant: merchant,
            cardLast4: cardLast4,
            bank: bank,
            date: date,
            category: category,
            rawSMS: sms
        )
    }
    
    // MARK: - Batch Parse
    func parseBatch(messages: [(body: String, date: Date)]) -> [ParsedTransaction] {
        messages.compactMap { msg in
            var result = parse(sms: msg.body)
            return result
        }
    }
    
    // MARK: - Helpers
    private func extractAmount(from text: String) -> Double? {
        for pattern in amountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amtStr = text[range].replacingOccurrences(of: ",", with: "")
                if let amt = Double(amtStr), amt > 0 {
                    return amt
                }
            }
        }
        return nil
    }
    
    private func extractMerchant(from text: String) -> String? {
        for pattern in merchantPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let merchant = String(text[range]).trimmingCharacters(in: .whitespaces)
                if !merchant.isEmpty && merchant.count > 2 {
                    return merchant.capitalized
                }
            }
        }
        return nil
    }
    
    private func extractCardLast4(from text: String) -> String? {
        for pattern in cardPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        return nil
    }
    
    private func extractBank(from text: String) -> String? {
        let upper = text.uppercased()
        for (keyword, bankName) in bankKeywords {
            if upper.contains(keyword) { return bankName }
        }
        return nil
    }
    
    private func extractDate(from text: String) -> Date? {
        let patterns = [
            #"(\d{2})[/-](\d{2})[/-](\d{2,4})"#,
            #"(\d{2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,]+(\d{2,4})"#,
        ]
        let formatter = DateFormatter()
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 0), in: text) {
                let dateStr = String(text[range])
                formatter.dateFormat = "dd/MM/yyyy"
                if let date = formatter.date(from: dateStr) { return date }
                formatter.dateFormat = "dd-MM-yyyy"
                if let date = formatter.date(from: dateStr) { return date }
                formatter.dateFormat = "dd-MM-yy"
                if let date = formatter.date(from: dateStr) { return date }
            }
        }
        return nil
    }
    
    func categorize(merchant: String, text: String) -> SpendCategory {
        let lower = merchant.lowercased() + " " + text.lowercased()
        
        for (keyword, category) in merchantCategoryMap {
            if lower.contains(keyword) { return category }
        }
        
        // Keyword fallback
        if lower.contains("upi/") || lower.contains("@upi") || lower.contains("upi-") { return .upi }
        if lower.contains("petrol") || lower.contains("diesel") || lower.contains("pump") { return .fuel }
        if lower.contains("flight") || lower.contains("hotel") || lower.contains("airline") { return .travel }
        if lower.contains("restaurant") || lower.contains("cafe") || lower.contains("kitchen") { return .dining }
        if lower.contains("medical") || lower.contains("pharmacy") || lower.contains("pharmacy") { return .medical }
        
        return .others
    }
    
    // MARK: - Match SMS to Card
    func matchCard(parsed: ParsedTransaction, cards: [CreditCard]) -> CreditCard? {
        // First: match by last 4 digits
        if let last4 = parsed.cardLast4 {
            // Check if any card name or identifier contains last 4
            // (You'd store last4 on the card in a real scenario)
        }
        
        // Second: match by bank name
        if let bank = parsed.bank {
            return cards.first { card in
                card.bankName.lowercased().contains(bank.lowercased().prefix(4)) ||
                bank.lowercased().contains(card.bankName.lowercased().prefix(4))
            }
        }
        
        return nil
    }
}

// MARK: - Rewards Engine
final class RewardsEngine {
    static let shared = RewardsEngine()
    private init() {}
    
    func calculateRewards(amount: Double, category: SpendCategory, card: CreditCard) -> Double {
        let rate = card.rewardRate(for: category)
        
        switch card.rewardType {
        case .cashback:
            return (amount * rate) / 100  // rate is % cashback
        case .points:
            return (amount / 100) * rate  // rate is points per ₹100
        case .miles:
            return (amount / 100) * rate  // rate is miles per ₹100
        }
    }
    
    func applyRewards(transaction: Transaction, card: inout CreditCard, context: ModelContext) {
        let rewards = calculateRewards(amount: transaction.amount,
                                        category: transaction.category,
                                        card: card)
        card.rewardBalance += rewards
        
        let history = RewardBalance(cardID: card.id,
                                     balance: rewards,
                                     description: "+\(rewardLabel(rewards, type: card.rewardType)) from \(transaction.merchant)")
        context.insert(history)
    }
    
    func reverseRewards(transaction: Transaction, card: inout CreditCard) {
        card.rewardBalance = max(0, card.rewardBalance - transaction.rewardsEarned)
    }
    
    func rewardLabel(_ value: Double, type: RewardType) -> String {
        switch type {
        case .cashback: return "₹\(String(format: "%.2f", value))"
        case .points: return "\(Int(value)) pts"
        case .miles: return "\(Int(value)) miles"
        }
    }
}
