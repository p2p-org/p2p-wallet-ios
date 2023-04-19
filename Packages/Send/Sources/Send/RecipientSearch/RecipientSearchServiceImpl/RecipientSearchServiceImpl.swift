// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService
import SolanaSwift
import Wormhole

public class RecipientSearchServiceImpl: RecipientSearchService {
    let nameService: NameService
    let solanaClient: SolanaAPIClient
    let swapService: SwapService

    public init(nameService: NameService, solanaClient: SolanaAPIClient, swapService: SwapService) {
        self.nameService = nameService
        self.solanaClient = solanaClient
        self.swapService = swapService
    }

    public func search(
        input: String,
        config: RecipientSearchConfig,
        preChosenToken: Token?
    ) async -> RecipientSearchResult {
        // Assertion
        guard !input.isEmpty else {
            return .ok([])
        }

        // Validate ethereum address.
        if config.ethereumSearch, EthereumAddressValidation.validate(input) {
            // Check self-sending
            if config.ethereumAccount == input.lowercased() {
                return .selfSendingError(
                    recipient: .init(address: input, category: .ethereumAddress, attributes: [])
                )
            }

            // Ok
            return .ok([
                .init(address: input, category: .ethereumAddress, attributes: []),
            ])
        }

        // Search by solana address
        if !input.contains(" "), let address = try? PublicKey(string: input), !address.bytes.isEmpty {
            return await searchBySolanaAddress(address, config: config, preChosenToken: preChosenToken)
        }

        // Search by name
        return await searchByName(input, config: config)
    }
}
