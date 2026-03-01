# CC Manager — Personal Credit Card App
### iOS 17+ · SwiftUI · SwiftData · MVVM

A private, offline-first credit card management app. Inspired by Apple Wallet + CRED aesthetics.

---

## ✅ Features Implemented

### 1. Card Management
- Add cards with name, bank, network (Visa/MC/Amex/RuPay), credit limit, outstanding, billing date, due date
- Upload actual card photo (auto-extracts dominant color)
- Manual color picker with presets (Regalia Gold, Amex Gold, Celesta Dark, etc.)
- 3-step guided add flow: Card Info → Design → Reward Rates
- Apple Wallet–style card widget with holographic feel
- Card detail view with utilisation %, days to due, reward balance

### 2. Dashboard
- Total credit limit, outstanding, available
- Real-time utilisation % with color-coded progress bar
- Upcoming dues alert (7-day window with overdue detection)
- Rewards earned this month (across all cards)
- Recent 5 transactions
- Smart Card Suggest shortcut

### 3. SMS Parsing (On-Device)
- Paste any Indian bank SMS
- Parses: amount, merchant, card last 4, bank name, date
- Categorizes automatically: Dining, Grocery, Travel, Fuel, Shopping, UPI, Utilities, Entertainment, Medical, Education, Others
- 100+ merchant → category mappings (Swiggy, Amazon, Zomato, IRCTC, BPCL, etc.)
- Manual card assignment in confirm step
- Bank pattern matching for 14 Indian banks (HDFC, ICICI, SBI, Axis, Amex, Federal, etc.)

### 4. Reward Auto-Tracking
- Per-card per-category reward rates (configurable)
- Auto-calculates points/cashback/miles on every transaction
- Cancel/Restore transactions → rewards auto-reversed
- Reward balance history

### 5. Smart Card Suggestion
- Type any merchant (Amazon, Swiggy, etc.) or select category
- Enter purchase amount
- App ranks ALL your cards by rewards earned
- Shows: earn rate label + calculated reward amount

### 6. Offers Tracker
- Add bank/merchant offers with validity dates
- Color-coded urgency (red < 3 days, orange < 7 days, green safe)
- Link offers to eligible cards
- Swipe to delete

### 7. Security
- Face ID / Touch ID lock on launch
- Graceful fallback if biometrics unavailable
- All data stored locally via SwiftData

### 8. Settings
- Toggle Face ID
- Export all transactions to CSV
- Reset all reward balances
- Swipe-to-delete cards

---

## 📁 File Structure

```
CCManager/
├── CCManagerApp.swift              # @main entry + Face ID gate
├── Info.plist                      # Permissions (FaceID, Photos)
│
├── Models/
│   └── Models.swift                # SwiftData models (CreditCard, Transaction, Offer, etc.)
│
├── Services/
│   └── SMSParserService.swift      # SMS parsing + rewards engine
│
├── Views/
│   ├── ContentView.swift           # TabView root
│   ├── LockScreenView.swift        # Biometric lock
│   │
│   ├── Dashboard/
│   │   └── DashboardView.swift     # Home screen
│   │
│   ├── Cards/
│   │   ├── CardsListView.swift     # Card list + detail + widget
│   │   └── AddCardView.swift       # 3-step add/edit flow
│   │
│   ├── Transactions/
│   │   └── TransactionsView.swift  # Transaction list + SMS import + manual add
│   │
│   └── OffersAndSettings.swift     # Offers, Smart Suggest, Milestones, Settings
```

---

## 🚀 Setup in Xcode

1. **Create new Xcode project**: iOS App → SwiftUI → SwiftData
2. **Copy all .swift files** into the project (maintaining folder structure)
3. **Replace** the generated `ContentView.swift` with ours
4. **Replace** `Info.plist` with the provided one
5. **Set minimum deployment target**: iOS 17.0
6. **Add capabilities**:
   - Go to target → Signing & Capabilities
   - Add: **Face ID** (included in LocalAuthentication framework — no extra entitlement needed)
   - PhotosUI is built-in
7. **Build & Run** on your personal device (not simulator for Face ID)

### Required Frameworks (auto-linked):
- `SwiftData` — local persistence
- `SwiftUI` — UI
- `LocalAuthentication` — Face ID/Touch ID
- `PhotosUI` — card image picker

---

## 🎨 Design Decisions

| Design Choice | Reason |
|---|---|
| Gold accent `#D4AF37` | Premium feel without purple — matches Indian premium card aesthetics |
| `Color(.systemGroupedBackground)` | Adapts to Light/Dark mode automatically |
| No fixed backgrounds | Follows system appearance |
| Card color extraction from photo | Makes each card feel unique, like the real thing |
| Swipe actions on transactions | iOS-native UX pattern |

---

## 🔜 Possible Enhancements

- iCloud sync via `ModelConfiguration` with CloudKit
- App Shortcuts (Siri / Spotlight: "Best card for Swiggy")
- Widgets (WidgetKit) showing upcoming dues
- Spend analytics charts (Charts framework)
- Card statement PDF import

---

## 📱 Card Color Presets

| Card | Background | Accent |
|---|---|---|
| HDFC Regalia Gold | `#3D2B1F` | `#D4AF37` |
| Amex Gold (MRCC) | `#B8960A` | `#F5D87A` |
| Federal Celesta | `#0D0D0D` | `#C9A84C` |
| ICICI Sapphiro | `#0A2040` | `#30D0D0` |
| SBI Card PRIME | `#002244` | `#FFD700` |
| Axis Magnus | `#4A0010` | `#FF6B6B` |
| Axis Horizon | `#1a0a2e` | `#7c3aed` |

---

*Personal use only. No server, no accounts, no tracking.*
