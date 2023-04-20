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
                slippage: 25
            )

            return bundle
        }
    }

    public func transferFromSolana(
        feePayer: String,
        from: String,
        recipient: String,
        mint: String?,
        amount: String
    ) async throws -> SendTransaction {
        guard let solanaKeyPair else {
            throw ServiceError.authorizationError
        }

        return try await api.transferFromSolana(
            userWallet: solanaKeyPair.publicKey.base58EncodedString,
            feePayer: feePayer,
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
}

public extension WormholeService {
    enum Error: Swift.Error {
        case invalidVSign
    }
}

private extension EthereumTransaction.TransactionType {
    var byte: UInt? {
        switch self {
        case .eip1559:
            return 0x02
        default:
            return nil
        }
    }
}
