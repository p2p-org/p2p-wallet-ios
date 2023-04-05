////
////  File.swift
////
////
////  Created by Giang Long Tran on 17.03.2023.
////
//
//import Combine
//import Foundation
//import KeyAppBusiness
//import KeyAppKitCore
//import SolanaSwift
//import Web3
//
//public class WormholeClaimMonitoreService: ObservableObject {
//    var subscriptions: [AnyCancellable] = []
//    let ethereumKeypair: EthereumKeyPair?
//    let api: WormholeAPI
//
//    let localBundles: AsyncValue<[WormholeBundleStatus]> = .init(just: [])
//    let remoteBundles: AsyncValue<[WormholeBundleStatus]>
//
//    var timer: Timer?
//
//    @Published public var bundles: AsyncValueState<[WormholeBundleStatus]> = .init(value: [])
//
//    init(ethereumKeypair: EthereumKeyPair?, api: WormholeAPI, errorObserver: ErrorObserver) {
//        self.ethereumKeypair = ethereumKeypair
//        self.api = api
//
//        remoteBundles = .init(initialItem: []) {
//            guard let ethereumKeypair else {
//                throw ServiceError.authorizationError
//            }
//
//            let fetchedBundles = try await api.listEthereumBundles(userWallet: ethereumKeypair.address)
//
//            return fetchedBundles
//        }
//
//        remoteBundles.listen(target: self, in: &subscriptions)
//        localBundles.listen(target: self, in: &subscriptions)
//
//        // Remove local bundles if remote bundle is present
//        remoteBundles.$state.sink { state in
//            self.localBundles.state.value = self.localBundles.state.value.filter { localBundle in
//                !state.value.map(\.bundleId).contains(localBundle.bundleId)
//            }
//        }
//        .store(in: &subscriptions)
//
//        // Merge sources
//        Publishers.CombineLatest(remoteBundles.$state, localBundles.$state)
//            .map { remoteBundles, localBundles in
//                // Filter to avoid dublicating
//                let filteredLocalBundles = localBundles.value
//                    .filter { localBundle in
//                        !remoteBundles.value.map(\.bundleId).contains(localBundle.bundleId)
//                    }
//
//                return AsyncValueState<[WormholeBundleStatus]>(
//                    status: remoteBundles.status,
//                    value: remoteBundles.value + Array(filteredLocalBundles),
//                    error: remoteBundles.error
//                )
//            }
//            .weakAssign(to: \.bundles, on: self)
//            .store(in: &subscriptions)
//
//        // Report error
//        errorObserver
//            .handleAsyncValue(remoteBundles.$state)
//            .store(in: &subscriptions)
//
//        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
//            self.remoteBundles.fetch()
//        }
//    }
//
//    deinit {
//        timer?.invalidate()
//    }
//
//    public func refresh() {
//        remoteBundles.fetch()
//    }
//
//    public func add(bundle: WormholeBundle) {
//        localBundles.state.value.append(.init(
//            bundleId: bundle.bundleId,
//            userWallet: bundle.userWallet,
//            recipient: bundle.recipient,
//            resultAmount: bundle.resultAmount,
//            fees: bundle.fees,
//            status: .pending
//        ))
//    }
//}
