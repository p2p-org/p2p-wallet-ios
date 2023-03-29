//
//  WormholeSendFeesAdapter.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

struct WormholeSendFeesAdapter: Equatable {
    struct Output: Equatable {
        let crypto: String
        let fiat: String
    }

    private let adapter: WormholeSendInputStateAdapter

    var recipientAddress: String {
        adapter.input?.recipient ?? ""
    }

    var receive: Output {
        .init(crypto: adapter.cryptoAmountString, fiat: adapter.amountInFiatString)
    }

    let networkFee: Output?

    let bridgeFee: Output?

    let arbiterFee: Output?

    let messageFee: Output?

    let total: Output?

    init(
        adapter: WormholeSendInputStateAdapter,
        ethereumTokensRepository: EthereumTokensRepository,
        solanaTokensRepository: SolanaTokensService
    ) async {
        self.adapter = adapter

        networkFee = await Self.resolve(
            fee: adapter.output?.fees.networkFee,
            ethereumTokensRepository: ethereumTokensRepository,
            solanaTokensRepository: solanaTokensRepository
        )

        bridgeFee = await Self.resolve(
            fee: adapter.output?.fees.bridgeFee,
            ethereumTokensRepository: ethereumTokensRepository,
            solanaTokensRepository: solanaTokensRepository
        )

        arbiterFee = await Self.resolve(
            fee: adapter.output?.fees.arbiter,
            ethereumTokensRepository: ethereumTokensRepository,
            solanaTokensRepository: solanaTokensRepository
        )

        messageFee = await Self.resolve(
            fee: adapter.output?.fees.messageAccountRent,
            ethereumTokensRepository: ethereumTokensRepository,
            solanaTokensRepository: solanaTokensRepository
        )

        let fees = [
            adapter.output?.fees.networkFee,
            adapter.output?.fees.bridgeFee,
            adapter.output?.fees.arbiter,
            adapter.output?.fees.messageAccountRent,
        ]
            .compactMap { $0 }

        var feesByToken = Dictionary(grouping: fees, by: \.token)
        
        total = nil
    }
    
    private static func resolve(
        fee: Wormhole.TokenAmount?,
        ethereumTokensRepository: EthereumTokensRepository,
        solanaTokensRepository: SolanaTokensService
    ) async -> Output? {
        if let fee {
            let token: AnyToken?

            switch fee.token {
            case let .ethereum(contract):
                if let contract {
                    token = try? await ethereumTokensRepository.resolve(address: contract)
                } else {
                    token = EthereumToken()
                }
            case let .solana(mint):
                if let mint {
                    let list = try? await solanaTokensRepository.getTokensList()
                    token = list?.first { $0.address == mint }
                } else {
                    token = SolanaToken.nativeSolana
                }
            }

            if let token = token {
                return Self.extract(tokenAmount: fee, token: token)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    private static func extract(tokenAmount: Wormhole.TokenAmount, token: AnyToken) -> Output {
        .init(
            crypto: CryptoFormatter().string(amount: .init(bigUIntString: tokenAmount.amount, token: token)),
            fiat: CurrencyFormatter().string(amount: tokenAmount)
        )
    }
}
