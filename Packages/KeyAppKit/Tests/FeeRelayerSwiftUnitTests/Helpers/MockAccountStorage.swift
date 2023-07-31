import Foundation
import SolanaSwift

class MockAccountStorage: SolanaAccountStorage {
    let account: KeyPair?
    
    init() async throws {
        account = try await KeyPair(
            phrase: "miracle pizza supply useful steak border same again youth silver access hundred".components(separatedBy: " "),
            network: .mainnetBeta
        )
    }
    
    func save(_ account: KeyPair) throws {}
}
