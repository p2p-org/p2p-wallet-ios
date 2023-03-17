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

    public let wormholeClaimMonitoreService: WormholeClaimMonitoreService

    let errorObservable: ErrorObserver

    public init(
        api: WormholeAPI,
        ethereumKeypair: EthereumKeyPair?,
        solanaKeyPair: KeyPair?,
        errorObservable: ErrorObserver
    ) {
        self.api = api
        self.ethereumKeypair = ethereumKeypair
        self.solanaKeyPair = solanaKeyPair
        self.errorObservable = errorObservable

        self.wormholeClaimMonitoreService = .init(
            ethereumKeypair: ethereumKeypair,
            api: api,
            errorObserver: errorObservable
        )

        wormholeClaimMonitoreService.refresh()
    }

    /// Method for get claiming bundle.
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

            // Request bundle
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

    public func simulateBundle(bundle: WormholeBundle) async throws {
        try await errorObservable.run {
            let signedBundle = try signBundle(bundle: bundle)
            try await api.simulateEthereumBundle(bundle: signedBundle)
        }
    }

    /// Submit bundle for starting claim.
    public func sendBundle(bundle: WormholeBundle) async throws {
        try await errorObservable.run {
            let signedBundle = try signBundle(bundle: bundle)
            try await api.sendEthereumBundle(bundle: signedBundle)
        }
    }

    /// Sign transaction
    internal func signBundle(bundle: WormholeBundle) throws -> WormholeBundle {
        guard let ethereumKeypair else {
            throw ServiceError.authorizationError
        }

        // Mutable bundle
        var bundle = bundle

        // Sign transactions
        bundle.signatures = try bundle.transactions.map { transaction -> EthereumSignature in
            let rlpItem: RLPItem = try RLPDecoder().decode(transaction.hexToBytes())

            let transaction = try EthereumTransaction(rlp: rlpItem)
            let signedTransaction = try ethereumKeypair.sign(transaction: transaction, chainID: 1)

            debugPrint(transaction)
            debugPrint(signedTransaction)

            print(signedTransaction.verifySignature())
            print(try signedTransaction.rawTransaction().hex())

            signedTransaction.verifySignature()

            let signature = EthereumSignature(
                r: signedTransaction.r.hex(),
                s: signedTransaction.s.hex(),
                v: try UInt64(signedTransaction.v.quantity)
            )

            debugPrint(signature)

            return signature
        }

        return bundle
    }
}

public extension WormholeService {
    enum Error: Swift.Error {
        case invalidVSign
    }
}
