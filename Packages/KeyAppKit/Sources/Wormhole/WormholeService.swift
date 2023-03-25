//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
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
    public func getBundle(account: EthereumAccount) async throws -> WormholeBundle {
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

            // Request bundle
            let bundle = try await api.getEthereumBundle(
                userWallet: ethereumKeypair.address,
                recipient: solanaKeyPair.publicKey.base58EncodedString,
                token: token,
                amount: String(account.balance),
                slippage: 5
            )

            return bundle
        }
    }

    public func simulateBundle(bundle: WormholeBundle) async throws {
        try await errorObservable.run {
            let signedBundle = try signBundle(bundle: bundle)
            try await api.simulateEthereumBundle(bundle: signedBundle)

            wormholeClaimMonitoreService.add(bundle: bundle)
        }
    }

    /// Submit bundle for starting claim.
    public func sendBundle(bundle: WormholeBundle) async throws {
        try await errorObservable.run {
            let signedBundle = try signBundle(bundle: bundle)
            try await api.sendEthereumBundle(bundle: signedBundle)

            wormholeClaimMonitoreService.add(bundle: bundle)
        }
    }

    public func transferFromSolana(
        feePayer: String,
        from: String,
        recipient: String,
        mint: String?,
        amount: String
    ) async throws -> [String] {
        guard let solanaKeyPair else {
            throw ServiceError.authorizationError
        }

        return try await api.transferFromSolana(
            userWallet: solanaKeyPair.publicKey.base58EncodedString,
            feePayer: solanaKeyPair.publicKey.base58EncodedString,
            from: from,
            recipient: recipient,
            mint: mint,
            amount: amount
        )
    }

    public func getTransferFees(
        recipient: String,
        mint: String?,
        amount: String
    ) async throws -> SendFees {
        guard let solanaKeyPair else {
            throw ServiceError.authorizationError
        }

        return try await api.getTransferFees(
            userWallet: solanaKeyPair.publicKey.base58EncodedString,
            recipient: recipient,
            mint: mint,
            amount: amount
        )
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

            print(signedTransaction.verifySignature())
            print(try signedTransaction.rawTransaction().hex())

            let signature = EthereumSignature(
                r: signedTransaction.r.hex(),
                s: signedTransaction.s.hex(),
                v: try UInt64(signedTransaction.v.quantity)
            )

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
