//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.04.2023.
//

import Foundation
import KeyAppKitCore
import Wormhole

public extension WormholeSendUserActionConsumer {
    func monitor() {
        Task { [weak self] in
            do {
                guard let address = self?.address else { return }

                let sendStatuses: [WormholeSendStatus]? = try await self?
                    .wormholeAPI
                    .listSolanaStatuses(userWallet: address)

                guard let sendStatuses else { return }

                for sendStatus in sendStatuses {
                    self?.handleEvent(event: .track(sendStatus))
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
                guard userAction.status == .processing else { continue }

                // Check
                do {
                    let bundleStatus = try await self?
                        .wormholeAPI
                        .getSolanaTransferStatus(message: userAction.message)

                    guard let bundleStatus else {
                        continue
                    }

                    self?.handleEvent(event: .track(bundleStatus))
                } catch is JSONRPCError<String> {
                    self?.handleEvent(event: .sendFailure(message: userAction.message, error: Error.sendingFailure))
                } catch {
                    continue
                }
            }
        }
    }
}
