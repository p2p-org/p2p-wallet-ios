import Foundation
import SolanaSwift
import OrcaSwapSwift
//
//class FakeAccountStorage: AccountStorage, OrcaSwapAccountProvider {
//    
//    private let seedPhrase: String
//    private let network: Network
//    
//    init(seedPhrase: String, network: Network) {
//        self.seedPhrase = seedPhrase
//        self.network = network
//    }
//    
//    func getAccount() -> Account? {
//        account
//    }
//    
//    func getNativeWalletAddress() -> PublicKey? {
//        account?.publicKey
//    }
//    
//    func save(_ account: Account) throws {}
//    
//    var account: Account? {
//        try! .init(phrase: seedPhrase.components(separatedBy: " "), network: network, derivablePath: .default)
//    }
//}
//
//class FakeNotificationHandler: OrcaSwapSignatureConfirmationHandler {
//    func waitForConfirmation(signature: String) -> Completable {
//        .empty()
//    }
//}
//
