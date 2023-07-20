import Foundation
import SolanaSwift

struct SendViaLinkTransactionInfo: Codable, Identifiable {
    let amount: Double
    let amountInFiat: Double
    let token: Token
    let seed: String
    let timestamp: Date
    
    var id: String {
        seed
    }
    
    var creationDayInString: String {
        // if today
        if Calendar.current.isDateInToday(timestamp) {
            return L10n.today
        } else if Calendar.current.isDateInYesterday(timestamp) {
            return L10n.yesterday
        }
        
        // if another day
        else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy"
            let someDateString = dateFormatter.string(from: timestamp)
            return someDateString
        }
    }
    
    var creationTimeInString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let someDateString = dateFormatter.string(from: timestamp)
        return someDateString
    }
}

#if DEBUG
extension Array where Element == SendViaLinkTransactionInfo {
    static var mocked: Self {
        [
            .init(
                amount: 10,
                amountInFiat: 20,
                token: .nativeSolana,
                seed: "UOO8ZTPqlwY3bJqE",
                timestamp: Date() // Today
            ),
            .init(
                amount: 1,
                amountInFiat: 0.99,
                token: .usdc,
                seed: "UOO8ZTPqlwY4bJqE",
                timestamp: Date()
                    .addingTimeInterval(-60*60*24*1) // This time yesterday
            ),
            .init(
                amount: 1,
                amountInFiat: 1.01,
                token: .usdt,
                seed: "UOO8ZTPqlwY5bJqE",
                timestamp: Date()
                    .addingTimeInterval(-60*60*24*2) // 2 days ago
            ),
            .init(
                amount: 100,
                amountInFiat: 1,
                token: .srm,
                seed: "UOO8ZTPqlwY6bJqE",
                timestamp: Date()
                    .addingTimeInterval(-60*60*24*1) // 3 days ago
            )
        ]
    }
}
#endif
