import Foundation
import SolanaSwift

class MockAccountStorage: SolanaAccountStorage {
    let account: Account?
    
    init() async throws {
        account = try await Account(
            phrase: "miracle pizza supply useful steak border same again youth silver access hundred".components(separatedBy: " "),
            network: .mainnetBeta
        )
    }
    
    func save(_ account: Account) throws {}
}
