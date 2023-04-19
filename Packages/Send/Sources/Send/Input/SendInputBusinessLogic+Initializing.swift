// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    static func initialize(
        state: SendInputState,
        services: SendInputServices,
        params: SendInputActionInitializeParams
    ) async -> SendInputState {
        do {
            var recipientAdditionalInfo = SendInputState.RecipientAdditionalInfo.zero

            switch state.recipient.category {
            case .solanaAddress, .username:
                // Analyse destination spl addresses
                recipientAdditionalInfo = try await .init(
                    walletAccount: services.solanaAPIClient.getAccountInfo(account: state.recipient.address),
                    splAccounts: services.solanaAPIClient
                        .getTokenAccountsByOwner(
                            pubkey: state.recipient.address,
                            params: .init(
                                mint: nil,
                                programId: TokenProgram.id.base58EncodedString
                            ),
                            configs: .init(encoding: "base64")
                        )
                )
            case let .solanaTokenAddress(walletAddress, _):
                recipientAdditionalInfo = try await .init(
                    walletAccount: services.solanaAPIClient.getAccountInfo(account: walletAddress.base58EncodedString),
                    splAccounts: services.solanaAPIClient
                        .getTokenAccountsByOwner(
                            pubkey: walletAddress.base58EncodedString,
                            params: .init(
                                mint: nil,
                                programId: TokenProgram.id.base58EncodedString
                            ),
                            configs: .init(encoding: "base64")
                        )
                )
            default:
                break
            }

            let state = state.copy(
                status: .ready,
                recipientAdditionalInfo: recipientAdditionalInfo,
                feeRelayerContext: try await params.feeRelayerContext()
            )

            return await changeToken(state: state, token: state.token, services: services)
        } catch {
            return state.copy(status: .error(reason: .initializeFailed(error as NSError)))
        }
    }
}
