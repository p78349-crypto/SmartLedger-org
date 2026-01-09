import AppIntents
import Foundation

// MARK: - 지출 기록 Intent
@available(iOS 16.0, *)
struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "지출 기록"
    static var description = IntentDescription("SmartLedger에서 지출을 기록합니다")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "금액")
    var amount: Double?
    
    @Parameter(title: "설명")
    var description: String?
    
    func perform() async throws -> some IntentResult & OpensIntent {
        // 딥링크 URL 생성
        var urlString = "smartledger://transaction/add?type=expense"
        if let amount = amount {
            urlString += "&amount=\(Int(amount))"
        }
        if let desc = description, !desc.isEmpty {
            urlString += "&description=\(desc.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? desc)"
        }
        
        // UserDefaults에 딥링크 저장 (앱에서 읽을 수 있도록)
        UserDefaults.standard.set(urlString, forKey: "pendingSiriDeepLink")
        
        return .result()
    }
}

// MARK: - 수입 기록 Intent
@available(iOS 16.0, *)
struct AddIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "수입 기록"
    static var description = IntentDescription("SmartLedger에서 수입을 기록합니다")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "금액")
    var amount: Double?
    
    func perform() async throws -> some IntentResult & OpensIntent {
        var urlString = "smartledger://transaction/add?type=income"
        if let amount = amount {
            urlString += "&amount=\(Int(amount))"
        }
        
        UserDefaults.standard.set(urlString, forKey: "pendingSiriDeepLink")
        return .result()
    }
}

// MARK: - 대시보드 열기 Intent
@available(iOS 16.0, *)
struct OpenDashboardIntent: AppIntent {
    static var title: LocalizedStringResource = "가계부 열기"
    static var description = IntentDescription("SmartLedger 대시보드를 엽니다")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & OpensIntent {
        UserDefaults.standard.set("smartledger://dashboard", forKey: "pendingSiriDeepLink")
        return .result()
    }
}

// MARK: - 기능 열기 Intent
@available(iOS 16.0, *)
struct OpenFeatureIntent: AppIntent {
    static var title: LocalizedStringResource = "기능 열기"
    static var description = IntentDescription("SmartLedger의 특정 기능을 엽니다")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "기능", optionsProvider: FeatureOptionsProvider())
    var feature: String
    
    func perform() async throws -> some IntentResult & OpensIntent {
        let urlString = "smartledger://feature/\(feature)"
        UserDefaults.standard.set(urlString, forKey: "pendingSiriDeepLink")
        return .result()
    }
    
    struct FeatureOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            return [
                "food_expiry",    // 유통기한
                "shopping_cart",  // 장바구니
                "assets",         // 자산
                "recipe",         // 레시피
                "calendar",       // 캘린더
                "stats"           // 통계
            ]
        }
    }
}

// MARK: - App Shortcuts Provider
@available(iOS 16.0, *)
struct SmartLedgerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "지출 기록 \(.applicationName)",
                "\(.applicationName)에서 지출 추가",
                "\(.applicationName) 지출 입력",
                "소비 기록 \(.applicationName)"
            ],
            shortTitle: "지출 기록",
            systemImageName: "minus.circle"
        )
        
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "수입 기록 \(.applicationName)",
                "\(.applicationName)에서 수입 추가",
                "\(.applicationName) 월급 기록"
            ],
            shortTitle: "수입 기록",
            systemImageName: "plus.circle"
        )
        
        AppShortcut(
            intent: OpenDashboardIntent(),
            phrases: [
                "\(.applicationName) 열어",
                "\(.applicationName) 가계부 확인",
                "지출 현황 \(.applicationName)",
                "이번달 지출 \(.applicationName)"
            ],
            shortTitle: "가계부 열기",
            systemImageName: "chart.pie"
        )
        
        AppShortcut(
            intent: OpenFeatureIntent(),
            phrases: [
                "\(.applicationName) 유통기한 확인",
                "\(.applicationName) 장바구니 열어",
                "\(.applicationName) 레시피 추천"
            ],
            shortTitle: "기능 열기",
            systemImageName: "square.grid.2x2"
        )
    }
}
