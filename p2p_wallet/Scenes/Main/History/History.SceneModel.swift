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
        private let fetchingConfiguration = FetchingConfiguration(
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
            Observable
                .zip(sources.map { source -> Observable<[SolanaSDK.SignatureInfo]> in
                    source.next(fetchingConfiguration).asObservable()
                })
                .map { results -> [SolanaSDK.SignatureInfo] in results.reduce([], +) }
                .map { signatures in signatures.unique(keyPath: \SolanaSDK.SignatureInfo.signature) }
                .flatMap { infos in Observable.from(infos) }
                .flatMap { [weak self] (info: SolanaSDK.SignatureInfo) in
                    guard let self = self else { return Observable.just(nil) }
                    return self.solanaSDK
                }
        }
    }
}
