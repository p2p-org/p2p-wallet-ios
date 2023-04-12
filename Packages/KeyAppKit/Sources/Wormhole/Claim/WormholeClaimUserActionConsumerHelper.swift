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
        Task { [weak self] in
            do {
                guard let address = self?.address else { return }

                let bundles: [WormholeBundleStatus]? = try await self?
                    .wormholeAPI
                    .listEthereumBundles(userWallet: address)

                guard let bundles else { return }

                for bundle in bundles {
                    self?.handleEvent(event: .track(bundle))
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

                    self?.handleEvent(event: .track(bundleStatus))
                } catch is JSONRPCError<String> {
                    self?.handleEvent(event: .claimFailure(bundleID: userAction.bundleID, reason: Error.claimFailure))
                } catch {
                    continue
                }
            }
        }
    }
}
