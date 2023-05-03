//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.04.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore

public extension WormholeClaimUserActionConsumer {
    func fetchNewBundle() {
        guard let address = address else { return }
        guard fetchNewBundleTask == nil else { return }

        fetchNewBundleTask = Task { [weak self] in
            do {
                // Clean after running
                defer {
                    self?.fetchNewBundleTask = nil
                }

                let bundles: [WormholeBundleStatus]? = try await self?
                    .wormholeAPI
                    .listEthereumBundles(userWallet: address)

                guard let bundles else { return }

                for bundle in bundles {
                    self?.handleInternalEvent(event: .track(bundle))
                }
            } catch {
                self?.errorObserver.handleError(error)
            }
        }
    }

    func manuallyCheck(userActions: [Action]) {
        Task { [weak self] in
            for userAction in userActions {
                // Filter only processing
                guard userAction.internalState == .processing else { continue }

                // Check
                do {
                    let bundleStatus = try await self?
                        .wormholeAPI
                        .getEthereumBundleStatus(bundleID: userAction.bundleID)

                    guard let bundleStatus else {
                        continue
                    }

                    self?.handleInternalEvent(event: .track(bundleStatus))
                } catch is JSONRPCError<String> {
                    self?
                        .handleInternalEvent(event: .claimFailure(bundleID: userAction.bundleID,
                                                                  reason: Error.claimFailure))
                } catch {
                    continue
                }
            }
        }
    }
}
