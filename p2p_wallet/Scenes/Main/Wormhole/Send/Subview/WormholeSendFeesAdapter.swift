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
    
    init(
        adapter: WormholeSendInputStateAdapter,
        ethereumTokensRepository: EthereumTokensRepository,
        solanaTokensRepository: SolanaTokensService
    ) async {
        self.adapter = adapter
        
        self.networkFee = await Self.resolve(
            fee: adapter.output?.fees.networkFee,
            ethereumTokensRepository: ethereumTokensRepository,
            solanaTokensRepository: solanaTokensRepository
        )
        
        self.bridgeFee = await Self.resolve(
            fee: adapter.output?.fees.bridgeFee,
            ethereumTokensRepository: ethereumTokensRepository,
            solanaTokensRepository: solanaTokensRepository
        )
        
        self.arbiterFee = await Self.resolve(
            fee: adapter.output?.fees.arbiter,
            ethereumTokensRepository: ethereumTokensRepository,
            solanaTokensRepository: solanaTokensRepository
        )
        
        self.messageFee = await Self.resolve(
            fee: adapter.output?.fees.messageAccountRent,
            ethereumTokensRepository: ethereumTokensRepository,
            solanaTokensRepository: solanaTokensRepository
        )
    }
    
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
        return .init(
            crypto: CryptoFormatter().string(amount: .init(bigUIntString: tokenAmount.amount, token: token)),
            fiat: CurrencyFormatter().string(amount: tokenAmount)
        )
    }
}
