//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import KeyAppBusiness

public enum WormholeService {
    typealias TokenBridge = (token: EthereumToken, solanaAddress: String)

    public static func supportedTokens(tokenService: EthereumTokensRepository) async throws -> [EthereumToken] {
        return try await withThrowingTaskGroup(of: EthereumToken.self) { group in
            SupportedToken.ERC20.allCases.forEach { token in
                group.addTask {
                    try await tokenService.resolve(address: token.rawValue)
                }
            }

            var tokens: [EthereumToken] = []
            for try await token in group {
                tokens.append(token)
            }

            return [EthereumToken()] + tokens
        }
    }
}
