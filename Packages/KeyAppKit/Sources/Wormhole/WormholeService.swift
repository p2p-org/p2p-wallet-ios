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
import Web3

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
            let slippage: UInt8?

            switch account.token.contractType {
            case .native:
                token = nil
                slippage = nil
            case let .erc20(contract: contract):
                token = contract.hex(eip55: false)
                slippage = 5
            }

            let bundle = try await api.getEthereumBundle(
                userWallet: ethereumKeypair.address,
                recipient: solanaKeyPair.publicKey.base58EncodedString,
                token: token,
                amount: String(account.balance),
                slippage: slippage
            )

            return bundle
        }
    }

    public func sendBundle(bundle: WormholeBundle) async throws {
        let signedBundle = try signBundle(bundle: bundle)
        try await api.sendEthereumBundle(bundle: signedBundle)
    }

    internal func signBundle(bundle: WormholeBundle) throws -> WormholeBundle {
        guard let ethereumKeypair else {
            throw ServiceError.authorizationError
        }

        // Mutable bundle
        var bundle = bundle

        // Sign transactions
        bundle.signatures = try bundle.transactions.map { transaction -> String in
            let rlpItem: RLPItem = try RLPDecoder().decode(transaction.hexToBytes())

            let transaction = try EthereumTransaction(rlp: rlpItem)
            let signedTransaction = try ethereumKeypair.sign(transaction: transaction)

            return try signedTransaction.rawTransaction().hex()
        }

        return bundle
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
