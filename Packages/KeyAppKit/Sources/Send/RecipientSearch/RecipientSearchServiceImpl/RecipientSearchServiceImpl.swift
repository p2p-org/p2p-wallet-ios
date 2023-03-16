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
        env: UserWalletEnvironments,
        preChosenToken: Token?
    ) async -> RecipientSearchResult {
        // assertion
        guard !input.isEmpty else {
            return .ok([])
        }
        if EthereumAddressValidation.validate(input) {
            return .ok([
                .init(address: input, category: .ethereumAddress, attributes: [])
            ])
        }

        // search by solana address
        if !input.contains(" "), let address = try? PublicKey(string: input), !address.bytes.isEmpty {
            return await searchBySolanaAddress(address, env: env, preChosenToken: preChosenToken)
        }

        // search by name
        return await searchByName(input, env: env)
    }
}
