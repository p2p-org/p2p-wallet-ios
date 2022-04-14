//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

extension History {
    class SceneModel: BEStreamListViewModel<SolanaSDK.ParsedTransaction> {
        private let disposeBag = DisposeBag()

        @Injected private var solanaSDK: SolanaSDK
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var feeRelayer: FeeRelayerAPIClientType

        /// A list of source, where data can be fetched
        private var sources: [StreamSource] = []

        /// Default fetching configuration
        private static let fetchingConfiguration = FetchingConfiguration(
            feePayer: Defaults.p2pFeePayerPubkeys,
            limit: 10
        )

        init() {
            super.init(isPaginationEnabled: true, limit: 10)

            sources = walletsRepository
                .getWallets()
                .map { wallet in AccountStreamSource(account: wallet.pubkey ?? "", accountSymbol: wallet.token.symbol) }
        }

        override func next() -> Observable<[SolanaSDK.ParsedTransaction]> {
            AsyncThrowingStream<[SolanaSDK.ParsedTransaction], Error> { stream in
                Task { [weak self] in
                    defer { stream.finish(throwing: nil) }
                    do {
                        var fetchingIds: [String] = []
                        for source in sources {
                            let history = try await source.next(SceneModel.fetchingConfiguration)
                            for trx in history {
                                if fetchingIds.contains(trx.signatureInfo.signature) { continue }
                                fetchingIds.append(trx.account)

                                let trx = try await solanaSDK.getTransaction(
                                    account: trx.account,
                                    accountSymbol: trx.accountSymbol,
                                    signature: trx.signatureInfo.signature,
                                    parser: SolanaSDK.TransactionParser(solanaSDK: solanaSDK),
                                    p2pFeePayerPubkeys: Defaults.p2pFeePayerPubkeys
                                ).value

                                stream.yield([trx])
                            }
                        }
                    } catch {
                        stream.finish(throwing: error)
                    }
                }
            }.asObservable()
        }
    }
}
