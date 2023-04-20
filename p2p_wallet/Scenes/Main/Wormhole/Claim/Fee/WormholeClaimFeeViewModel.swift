import AnalyticsManager
import BigInt
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

class WormholeClaimFeeViewModel: BaseViewModel, ObservableObject {
    typealias Amount = (crypto: String, fiat: String, isFree: Bool)

    @Injected private var analyticsManager: AnalyticsManager

    let closeAction: PassthroughSubject<Void, Never> = .init()

    @Published var fee: AsyncValueState<WormholeClaimFee?> = .init(value: nil)

    override init() {
        super.init()
        analyticsManager.log(event: .claimBridgesFeeClick)
    }

    convenience init(
        receive: Amount,
        networkFee: Amount,
        accountCreationFee: Amount?,
        wormholeBridgeAndTrxFee: Amount
    ) {
        self.init()
        fee = .init(
            status: .ready,
            value: .init(
                receive: receive,
                networkFee: networkFee,
                accountCreationFee: accountCreationFee,
                wormholeBridgeAndTrxFee: wormholeBridgeAndTrxFee
            )
        )
    }

    convenience init(bundle: AsyncValue<WormholeBundle?>) {
        self.init()

        let aggregator = WormholeClaimFeeAggregator()

        /// Listen to changing in bundle
        bundle
            .statePublisher
            .map { state in
                state.apply { bundle in
                    aggregator.transform(input: bundle)
                }
            }
            .assignWeak(to: \WormholeClaimFeeViewModel.fee, on: self)
            .store(in: &subscriptions)
    }

    func close() {
        closeAction.send()
    }
}
