import Foundation
import NameService
import SolanaSwift

extension RecipientSearchServiceImpl {
    /// Search by name
    func searchByName(_ input: String, env: UserWalletEnvironments) async -> RecipientSearchResult {
        do {
            let orders: [String: Int] = ["key": 2, "sol": 1, "": 0]
            let records: [NameRecord] = try await nameService.getOwners(input.lowercased())
            let recipients: [Recipient] = records
                .map { record in
                    if let name = record.name {
                        let (name, domain) = UsernameUtils.splitIntoNameAndDomain(rawName: name)
                        return .init(
                            address: record.owner,
                            category: .username(name: name, domain: domain),
                            attributes: [.funds]
                        )
                    } else {
                        return .init(
                            address: record.owner,
                            category: .solanaAddress,
                            attributes: [.funds]
                        )
                    }
                }
                .filter { (recipient: Recipient) -> Bool in
                    !env.wallets.contains { (wallet: Wallet) in wallet.pubkey == recipient.address }
                }
                .sorted { (lhs: Recipient, rhs: Recipient) in
                    switch (lhs.category, rhs.category) {
                    case let (.username(_, lhsDomain), .username(_, rhsDomain)):
                        return (orders[lhsDomain] ?? 0) > (orders[rhsDomain] ?? 0)
                    case (.username(_, _), _):
                        return true
                    default:
                        return false
                    }
                }

            return .ok(recipients)
        } catch {
            debugPrint(error)
            return .nameServiceError(error as NSError)
        }
    }
}
