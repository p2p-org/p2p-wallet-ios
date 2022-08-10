//
//  Preparing.SceneModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Combine
import Foundation
import Resolver
import SolanaSwift

protocol BuyPreparingSceneModel: BESceneModel {
    func setAmount(value: Double?)
    func swap()

    var inputAnyPublisher: AnyPublisher<Buy.ExchangeInput, Never> { get }
    var outputAnyPublisher: AnyPublisher<Buy.ExchangeOutput, Never> { get }
    var minFiatAmount: AnyPublisher<Double, Never> { get }
    var minCryptoAmount: AnyPublisher<Double, Never> { get }
    var exchangeRateAnyPublisher: AnyPublisher<Buy.ExchangeRate?, Never> { get }
    var input: Buy.ExchangeInput { get }
    var crypto: Buy.CryptoCurrency { get }
    var amount: Double { get }
    var walletsRepository: WalletsRepository { get }
    var solanaTokenPublisher: AnyPublisher<Token?, Never> { get }
}

extension BuyPreparing {
    class SceneModel: ObservableObject, BuyPreparingSceneModel {
        private let exchangeService: Buy.ExchangeService
        private var subscriptions = [AnyCancellable]()

        @Injected var walletsRepository: WalletsRepository

        let crypto: Buy.CryptoCurrency
        @Published private var errorRelay: String?
        @Published private var inputRelay = Buy.ExchangeInput(amount: 0, currency: Buy.FiatCurrency.usd)
        @Published private var outputRelay: Buy.ExchangeOutput
        @Published private var minFiatAmountsRelay = 0.0
        @Published private var minCryptoAmountsRelay = 0.0
        @Published private var exchangeRateRelay: Buy.ExchangeRate?
        @Published private var solanaToken: Token?
        private let updateTimer = Timer.publish(every: 10, on: .main, in: .default).autoconnect()

        init(crypto: Buy.CryptoCurrency, exchangeService: Buy.ExchangeService) {
            self.crypto = crypto
            self.exchangeService = exchangeService
            outputRelay = .init(
                amount: 0,
                currency: crypto,
                processingFee: 0,
                networkFee: 0,
                purchaseCost: 0,
                total: 0
            )

            updateTimer
                .sink { [weak self] _ in
                    Task { [weak self] in
                        try? await self?.update()
                    }
                }
                .store(in: &subscriptions)

            Publishers.CombineLatest(
                $inputRelay,
                updateTimer
            )
                .receive(on: RunLoop.main)
                .asyncMap { [weak self] input, _ -> Buy.ExchangeOutput in
                    guard let self = self
                    else { throw NSError(domain: "Preparing", code: -1) }

                    if input.amount == 0 {
                        return .init(
                            amount: 0,
                            currency: self.outputRelay.currency,
                            processingFee: 0,
                            networkFee: 0,
                            purchaseCost: 0,
                            total: 0
                        )
                    }

                    return try await self.exchangeService
                        .convert(
                            input: input,
                            to: input.currency is Buy.FiatCurrency ? crypto : Buy.FiatCurrency.usd
                        )
                }
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.errorRelay = nil
                }, receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.errorRelay = nil
                    case let .failure(error):
                        guard let self = self else { return }
                        if let error = error as? Buy.Exception {
                            switch error {
                            case .invalidInput:
                                self.errorRelay = "Invalid input"
                            case let .message(message):
                                self.errorRelay = message
                            }

                        } else {
                            self.errorRelay = error.localizedDescription
                        }
                    }
                })
                .replaceError(with: .init(
                    amount: 0,
                    currency: outputRelay.currency,
                    processingFee: 0,
                    networkFee: 0,
                    purchaseCost: 0,
                    total: 0
                ))
                .assign(to: \.outputRelay, on: self)
                .store(in: &subscriptions)

            Task {}
        }

        private func update() async throws {
            let (exchangeRate, minCryptoAmount, minFiatAmount) = try await(
                exchangeService.getExchangeRate(from: .usd, to: crypto),
                exchangeService.getMinAmount(currency: crypto),
                exchangeService.getMinAmount(currency: Buy.FiatCurrency.usd)
            )

            exchangeRateRelay = exchangeRate
            minCryptoAmountsRelay = minCryptoAmount

            let mfa = max(ceil(minCryptoAmount * exchangeRate.amount), minFiatAmount)
                .rounded(decimals: 2)
            minFiatAmountsRelay = mfa
        }

        func setAmount(value: Double?) {
            if value == input.amount { return }
            // Update amount
            inputRelay = .init(
                amount: value ?? 0,
                currency: inputRelay.currency
            )
        }

        func swap() {
            let (input, output) = inputRelay.swap(with: outputRelay)
            outputRelay = output
            inputRelay = input
        }

        var inputAnyPublisher: AnyPublisher<Buy.ExchangeInput, Never> {
            $inputRelay.receive(on: RunLoop.main).eraseToAnyPublisher()
        }

        var outputAnyPublisher: AnyPublisher<Buy.ExchangeOutput, Never> {
            $outputRelay.receive(on: RunLoop.main).eraseToAnyPublisher()
        }

        var exchangeRateAnyPublisher: AnyPublisher<Buy.ExchangeRate?, Never> {
            $exchangeRateRelay.receive(on: RunLoop.main).eraseToAnyPublisher()
        }

        var input: Buy.ExchangeInput { inputRelay }

        var minFiatAmount: AnyPublisher<Double, Never> {
            $minFiatAmountsRelay.receive(on: RunLoop.main).eraseToAnyPublisher()
        }

        var minCryptoAmount: AnyPublisher<Double, Never> {
            $minCryptoAmountsRelay.receive(on: RunLoop.main).eraseToAnyPublisher()
        }

        var amount: Double { outputRelay.total }

        var solanaTokenPublisher: AnyPublisher<Token?, Never> {
            $solanaToken.receive(on: RunLoop.main).eraseToAnyPublisher()
        }
    }
}
