import Foundation
import History
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

final class AccountDetailsHistoryViewModel: HistoryViewModel {
    let account: SolanaAccount

    init(
        mint: String,
        account: SolanaAccount
    ) {
        self.account = account
        super.init(mint: mint)
    }
}
