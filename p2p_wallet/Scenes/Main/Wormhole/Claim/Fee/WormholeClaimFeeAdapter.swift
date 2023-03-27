//
//  WormholeClaimFeeAdapter.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 27.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

struct WormholeClaimFeeAdapter {
    typealias Amount = (crypto: String, fiat: String, isFree: Bool)

    let receive: Amount?

    let networkFee: Amount?

    let accountCreationFee: Amount?

    let wormholeBridgeAndTrxFee: Amount?

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
    }

    init(
        account: EthereumAccount,
        state: AsyncValueState<WormholeBundle?>,
        ethereumTokenService _: EthereumTokensRepository = Resolver.resolve(),
        solanaTokenService _: SolanaTokensRepository = Resolver.resolve()
    ) async {
        guard let bundle = state.value else {
            receive = nil
            networkFee = nil
            accountCreationFee = nil
            wormholeBridgeAndTrxFee = nil
            return
        }

        let cryptoFormatter = CryptoFormatter()
        let currencyFormatter = CurrencyFormatter()

        let cryptoAmount = CryptoAmount(
            bigUIntString: bundle.resultAmount.amount,
            token: account.token
        )

        receive = (
            cryptoFormatter.string(amount: cryptoAmount),
            currencyFormatter.string(for: account.balanceInFiat) ?? "",
            false
        )

        if bundle.compensationDeclineReason == nil {
            networkFee = (L10n.paidByKeyApp, L10n.free, true)
            accountCreationFee = (L10n.paidByKeyApp, L10n.free, true)
            wormholeBridgeAndTrxFee = (L10n.paidByKeyApp, L10n.free, true)
        } else {
            // Network fee
            do {
                let networkCryptoAmount = try await WormholeClaimViewModel.resolveCrytoAmount(
                    amount: bundle.fees.gas.amount,
                    feeToken: bundle.fees.gas.token
                )

                networkFee = (
                    cryptoFormatter.string(amount: networkCryptoAmount),
                    currencyFormatter.string(amount: bundle.fees.gas),
                    false
                )
            } catch {
                networkFee = nil
                error.capture()
            }

            do {
                // Accounts fee
                if let createAccount = bundle.fees.createAccount {
                    let accountsCryptoAmount = try await WormholeClaimViewModel.resolveCrytoAmount(
                        amount: createAccount.amount,
                        feeToken: createAccount.token
                    )

                    accountCreationFee = (
                        cryptoFormatter.string(amount: accountsCryptoAmount),
                        currencyFormatter.string(amount: createAccount),
                        false
                    )
                } else {
                    accountCreationFee = nil
                }
            } catch {
                accountCreationFee = nil
                error.capture()
            }

            do {
                // Network fee
                let arbiterAmount = try await WormholeClaimViewModel.resolveCrytoAmount(
                    amount: bundle.fees.arbiter.amount,
                    feeToken: bundle.fees.arbiter.token
                )

                wormholeBridgeAndTrxFee = (
                    cryptoFormatter.string(amount: arbiterAmount),
                    currencyFormatter.string(amount: bundle.fees.arbiter),
                    false
                )
            } catch {
                wormholeBridgeAndTrxFee = nil
                error.capture()
            }
        }
    }

    static func resolveCrytoAmount(
        amount: String,
        feeToken: Wormhole.WormholeToken,
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

            return CryptoAmount(bigUIntString: amount, token: token)
        case let .ethereum(address):
            if let address {
                let token = try await ethereumTokenRepository.resolve(address: address)
                return CryptoAmount(bigUIntString: amount, token: token)
            } else {
                return CryptoAmount(bigUIntString: amount, token: EthereumToken())
            }
        }
    }

    enum ResolveError: Swift.Error {
        case canNotResolveToken
    }
}
