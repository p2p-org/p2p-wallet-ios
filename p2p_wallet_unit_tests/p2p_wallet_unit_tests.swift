////
////  p2p_wallet_unit_tests.swift
////  p2p_wallet_unit_tests
////
////  Created by Giang Long Tran on 10.02.2022.
////
//
//import XCTest
//@testable import p2p_wallet
//@testable import FeeRelayerSwift
//@testable import OrcaSwapSwift
//import RxSwift
//import RxCocoa
//import RxBlocking
//
//class RentBTCImplUnitTests: XCTestCase {
//
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func testCreateRentBTCAccount() throws {
//        let endpoint = SolanaSDK.APIEndPoint(address: "https://api.devnet.solana.com", network: .devnet)
//
//        let phrase = Mnemonic().phrase
//        let accountStorage = InMemoryAccountStorage(account: try SolanaSDK.Account(phrase: phrase, network: .devnet))
//
//        let solanaSDK = SolanaSDK(endpoint: endpoint, accountStorage: accountStorage)
//
//        let feeRelayerApi = FeeRelayer.APIClient(version: 2) // v2 for devnet
//
//        let orcaSwapApi = OrcaSwap.APIClient(network: endpoint.network.cluster)
//        let orcaSwap = OrcaSwap(
//            apiClient: orcaSwapApi,
//            solanaClient: solanaSDK,
//            accountProvider: accountStorage,
//            notificationHandler: OrcaListener()
//        )
//        try orcaSwap.load().toBlocking().first()
//
//        let rentBTC = RentBtcServiceImpl(
//            solanaSDK: solanaSDK,
//            feeRelayerApi: feeRelayerApi,
//            accountStorage: accountStorage,
//            orcaSwap: orcaSwap
//        )
//        try rentBTC.load().toBlocking().first()
//
//        // Request airdrop
//        var trx = try solanaSDK.requestAirdrop(account: accountStorage.account!.publicKey.base58EncodedString, lamports: 10000000).toBlocking().first()
//        print(trx)
//        solanaSDK.waitForConfirmation(signature: trx!).toBlocking()
//
////        let usdcMint = "EmXq3Ni9gfudTiyNKzzYvpnQqnJEMRw2ttnVXoJXjLo1"
//
////        let route = try orcaSwap.getTradablePoolsPairs(fromMint: SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString, toMint: usdcMint).toBlocking().first()
////        let swapOperation = try orcaSwap.swap(
////            fromWalletPubkey: accountStorage.account!.publicKey.base58EncodedString,
////            toWalletPubkey: accountStorage.account!.publicKey.base58EncodedString,
////            bestPoolsPair: try orcaSwap.findBestPoolsPairForEstimatedAmount(0, from: route!)!,
////            amount: 10, slippage: 0.1
////        ).toBlocking().first()
////        print(swapOperation!.transactionId)
////        solanaSDK.waitForConfirmation(signature: swapOperation!.transactionId).toBlocking()
//
//
//        var isRentBTCAccontCreated = try rentBTC.hasAssociatedTokenAccountBeenCreated().toBlocking().first()
//        XCTAssertEqual(isRentBTCAccontCreated, false, "This account already has rentBTC account. Please run the test again.")
//
//        let transactionID = try rentBTC.createAssociatedTokenAccount(
//            payingFeeAddress: accountStorage.account!.publicKey.base58EncodedString,
//            payingFeeMintAddress: SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
//        ).toBlocking().first()
//        print(transactionID)
//
//        let status = try solanaSDK.waitUntilConfirmed(transactionID!).toBlocking().first()
//
//        isRentBTCAccontCreated = try rentBTC.hasAssociatedTokenAccountBeenCreated().toBlocking().first()
//        XCTAssertEqual(isRentBTCAccontCreated, true, "This account should have rentBTC account.")
//    }
//}
//
//extension SolanaSDK {
//    fileprivate func waitUntilConfirmed(_ id: String, retry: Int = 10) -> Single<SignatureStatus> {
//        var retry = retry
//
//        return .create { single in
//            let subscribe = BehaviorRelay(value: true)
//                .takeWhile{ $0 && retry > 0 }
//                .flatMap { value in Observable<Int>.timer(RxTimeInterval.seconds(5), scheduler: MainScheduler.instance) }
//                .flatMap { value -> Single<SignatureStatus> in self.getSignatureStatus(signature: id) }
//                .do { value in
//                    print(value)
//                    if value.confirmationStatus == "confirmed" {
//                        single(.success(value))
//                    } else {
//                        retry = retry - 1
//                    }
//                }
//                .subscribe()
//
//            return Disposables.create {
//                subscribe.dispose()
//            }
//        }
//    }
//}
//
//private class OrcaListener: OrcaSwapSignatureConfirmationHandler {
//    func waitForConfirmation(signature: String) -> RxSwift.Completable {
//        .empty()
//    }
//}
//
//private class InMemoryAccountStorage: AccountStorageType, OrcaSwapAccountProvider {
//    var account: SolanaSDK.Account?
//
//    init(account: SolanaSDK.Account) {
//        self.account = account
//    }
//
//    func save(_ account: SolanaSDK.Account) throws {
//        self.account = account
//    }
//
//    func getAccount() -> OrcaSwap.Account? {
//        account
//    }
//
//    func getNativeWalletAddress() -> OrcaSwap.PublicKey? {
//        account?.publicKey
//    }
//
//    var phrases: [String]? {
//        account?.phrase
//    }
//
//    func getDerivablePath() -> SolanaSDK.DerivablePath? {
//        fatalError()
//    }
//
//    func save(phrases: [String]) throws {
//        fatalError()
//    }
//
//    func save(derivableType: SolanaSDK.DerivablePath.DerivableType) throws {
//        fatalError()
//    }
//
//    func save(walletIndex: Int) throws {
//        fatalError()
//    }
//
//    func clearAccount() {
//        fatalError()
//    }
//}
