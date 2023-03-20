//
//  WormholeClaimFeeViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.03.2023.
//

import BigInt
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

class WormholeClaimFeeViewModel: BaseViewModel, ObservableObject {
    typealias Amount = (crypto: String, fiat: String, isFree: Bool)

    let closeAction: PassthroughSubject<Void, Never> = .init()

    @Published var receive: Amount?

    @Published var networkFee: Amount?

    @Published var accountCreationFee: Amount?

    @Published var wormholeBridgeAndTrxFee: Amount?

    init(
        receive: Amount,
        networkFee: Amount?,
        accountCreationFee: Amount?,
        wormholeBridgeAndTrxFee: Amount?
    ) {
        self.receive = receive
        self.networkFee = networkFee
        self.accountCreationFee = accountCreationFee
        self.wormholeBridgeAndTrxFee = wormholeBridgeAndTrxFee

        super.init()
    }

    init(
        account: EthereumAccountsService.Account,
        bundle: AsyncValue<WormholeBundle?>,
        ethereumTokenService: EthereumTokensRepository = Resolver.resolve(),
        solanaTokenService: TokensRepository = Resolver.resolve()
    ) {
        let cryptoFormatter = CryptoFormatter()
        let currencyFormatter = CurrencyFormatter()

        self.receive = nil
        self.networkFee = nil
        self.accountCreationFee = nil
        self.wormholeBridgeAndTrxFee = nil

        super.init()

        /// Listen to changing in bundle
        bundle
            .$state
            .sinkAsync { [weak self] state in
                guard let self = self else { return }
                guard let bundle = state.value else {
                    self.receive = nil
                    self.networkFee = nil
                    self.accountCreationFee = nil
                    self.wormholeBridgeAndTrxFee = nil
                    return
                }

                let cryptoAmount = CryptoAmount(
                    bigUInt: BigUInt(stringLiteral: bundle.resultAmount.amount),
                    symbol: account.token.symbol,
                    decimals: account.token.decimals
                )

                let fiatAmount = CurrencyAmount(usd: Decimal(string: bundle.resultAmount.usdAmount) ?? 0)

                self.receive = (
                    cryptoFormatter.string(amount: cryptoAmount),
                    currencyFormatter.string(for: account.balanceInFiat) ?? "",
                    false
                )

                // Network fee
                let networkCryptoAmount = try await WormholeClaimViewModel.resolveCrytoAmount(
                    amount: bundle.fees.gas.amount,
                    feeToken: bundle.fees.gas.feeToken
                )

                self.networkFee = (
                    cryptoFormatter.string(amount: networkCryptoAmount),
                    currencyFormatter.string(amount: CurrencyAmount(fee: bundle.fees.gas)),
                    networkCryptoAmount.amount == 0
                )

                // Accounts fee
                if let createAccount = bundle.fees.createAccount {
                    let accountsCryptoAmount = try await WormholeClaimViewModel.resolveCrytoAmount(
                        amount: createAccount.amount,
                        feeToken: createAccount.feeToken
                    )

                    self.accountCreationFee = (
                        cryptoFormatter.string(amount: accountsCryptoAmount),
                        currencyFormatter.string(amount: CurrencyAmount(fee: createAccount)),
                        accountsCryptoAmount.amount == 0
                    )
                }

                // Network fee
                let arbiterAmount = try await WormholeClaimViewModel.resolveCrytoAmount(
                    amount: bundle.fees.arbiter.amount,
                    feeToken: bundle.fees.arbiter.feeToken
                )

                self.wormholeBridgeAndTrxFee = (
                    cryptoFormatter.string(amount: arbiterAmount),
                    currencyFormatter.string(amount: CurrencyAmount(fee: bundle.fees.arbiter)),
                    arbiterAmount.amount == 0
                )
            }
            .store(in: &subscriptions)
    }

    func close() {
        closeAction.send()
    }
}

extension WormholeClaimViewModel {
    enum ResolveError: Swift.Error {
        case canNotResolveToken
    }

    static func resolveCrytoAmount(
        amount: String,
        feeToken: Wormhole.FeeToken,
        solanaTokenRepository: TokensRepository = Resolver.resolve(),
        ethereumTokenRepository: EthereumTokensRepository = Resolver.resolve()
    ) async throws -> CryptoAmount {
        switch feeToken {
        case let .solana(address):
            let tokens = try await solanaTokenRepository.getTokensList()
            let token: Token? = tokens.first { $0.address == address }
            guard let token else {
                throw WormholeClaimViewModel.ResolveError.canNotResolveToken
            }

            return CryptoAmount(
                bigUInt: BigUInt(stringLiteral: amount),
                symbol: token.symbol,
                decimals: token.decimals
            )
        case let .ethereum(address):
            if let address {
                let token = try await ethereumTokenRepository.resolve(address: address)
                return CryptoAmount(
                    bigUInt: BigUInt(stringLiteral: amount),
                    symbol: token.symbol,
                    decimals: token.decimals
                )
            } else {
                let token = EthereumToken()
                return CryptoAmount(
                    bigUInt: BigUInt(stringLiteral: amount),
                    symbol: token.symbol,
                    decimals: token.decimals
                )
            }
        }
    }
}
