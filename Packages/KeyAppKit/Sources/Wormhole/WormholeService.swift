//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift

public class WormholeService {
    let api: WormholeAPI

    private let ethereumKeypair: EthereumKeyPair?
    private let solanaKeyPair: KeyPair?

    let errorObservable: ErrorObserver

    public init(api: WormholeAPI, ethereumKeypair: EthereumKeyPair?, solanaKeyPair: KeyPair?, errorObservable: ErrorObserver) {
        self.api = api
        self.ethereumKeypair = ethereumKeypair
        self.solanaKeyPair = solanaKeyPair
        self.errorObservable = errorObservable
    }

    public func getBundle(account: EthereumAccountsService.Account) async throws -> WormholeBundle {
        try await errorObservable.run {
            guard let ethereumKeypair, let solanaKeyPair else {
                throw ServiceError.authorizationError
            }

            // Detect token (native token or erc-20 token)
            let token: String?

            switch account.token.contractType {
            case .native:
                token = nil
            case let .erc20(contract: contract):
                token = contract.hex(eip55: false)
            }

            let bundle = try await api.getEthereumBundle(
                userWallet: ethereumKeypair.address,
                recipient: solanaKeyPair.publicKey.base58EncodedString,
                token: token,
                amount: String(account.balance),
                slippage: nil
            )

            return bundle
        }
    }

    func signBundle(bundle: WormholeBundle) async throws -> WormholeBundle {
        guard let ethereumKeypair else {
            throw ServiceError.authorizationError
        }

        bundle.signatures = bundle.transactions.map { transaction -> String in
            let decodedRawTrasaction: RLPItem = try RLPDecoder().decode(transaction.hexToBytes())
            
            EthereumTransaction
        }
    }

//    typealias TokenBridge = (token: EthereumToken, solanaAddress: String)
//
//    public static func supportedTokens(tokenService: EthereumTokensRepository) async throws -> [EthereumToken] {
//        return try await withThrowingTaskGroup(of: EthereumToken.self) { group in
//            SupportedToken.ERC20.allCases.forEach { token in
//                group.addTask {
//                    try await tokenService.resolve(address: token.rawValue)
//                }
//            }
//
//            var tokens: [EthereumToken] = []
//            for try await token in group {
//                tokens.append(token)
//            }
//
//            return tokens
//        }
//    }
}
