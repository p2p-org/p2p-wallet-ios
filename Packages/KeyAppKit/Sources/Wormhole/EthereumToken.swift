//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import KeyAppBusiness

extension EthereumTokensRepository {
    func wormholeERC20Tokens() async throws -> [EthereumToken] {
        return try await withThrowingTaskGroup(of: EthereumToken.self) { group in
            SupportedToken.ERC20.allCases.forEach { token in
                group.addTask {
                    try await self.resolve(address: token.rawValue)
                }
            }

            var tokens: [EthereumToken] = []
            for try await token in group {
                tokens.append(token)
            }

            return tokens
        }
    }
}
