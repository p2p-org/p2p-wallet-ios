// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import NameService
import SolanaSwift
import XCTest
@testable import Send

class SendInputBusinessLogicInputTests: XCTestCase {
    let defaultUserWalletState: UserWalletEnvironments = .init(
        wallets: [.nativeSolana(pubkey: "8JmwhqewSppZ2sDNqGZoKu3bWh8wUKZP8mdbP4M1XQx1", lamport: 30_000_000)],
        exchangeRate: ["SOL": .init(value: 12.5)],
        tokens: [.nativeSolana]
    )

    let services: SendInputServices = .init(
        swapService: MockedSwapService(result: nil),
        feeService: SendFeeCalculatorImpl(feeRelayerCalculator: DefaultRelayFeeCalculator()),
        solanaAPIClient: MockedSolanaAPIClient()
    )

    private func feeContext(currentUsage: Int = 0) -> RelayContext {
        .init(
            minimumTokenAccountBalance: 2_039_280,
            minimumRelayAccountBalance: 890_880,
            feePayerAddress: "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT",
            lamportsPerSignature: 5000,
            relayAccountStatus: .notYetCreated,
            usageStatus: .init(
                maxUsage: 100,
                currentUsage: currentUsage,
                maxAmount: 1_000_000,
                amountUsed: 0
            )
        )
    }

    /// Change input amount
    ///
    /// Token: SOL
    func testChangeInToken() async throws {
        let initialState = SendInputState.zero(
            status: .ready,
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            feeRelayerContext: feeContext(),
            sendViaLinkSeed: nil
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeAmountInToken(0.001),
            services: services
        )

        XCTAssertEqual(nextState.amountInToken, 0.001)
        XCTAssertEqual(nextState.amountInFiat, 0.0125)
        XCTAssertEqual(nextState.status, .ready)
    }

    /// Change input amount to max
    ///
    /// Token: SOL
    func testChangeInTokenToMax() async throws {
        let initialState = SendInputState.zero(
            status: .ready,
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            feeRelayerContext: feeContext(),
            sendViaLinkSeed: nil
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeAmountInToken(initialState.maxAmountInputInToken),
            services: services
        )

        XCTAssertEqual(nextState.amountInToken, 0.03)
        XCTAssertEqual(nextState.amountInFiat, 0.375)
        XCTAssertEqual(nextState.status, .ready)
    }

    /// Change input in token to max
    ///
    /// Token: SOL
    func testChangeInTokenInputTooLarge() async throws {
        let initialState = SendInputState.zero(
            status: .ready,
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            feeRelayerContext: feeContext(),
            sendViaLinkSeed: nil
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeAmountInToken(0.05),
            services: services
        )

        XCTAssertEqual(nextState.amountInToken, 0.05)
        XCTAssertEqual(nextState.amountInFiat, 0.625)
        XCTAssertEqual(nextState.status, .error(reason: .inputTooHigh(0.05)))
    }

    /// Change input in fiat
    ///
    /// Token: SOL
    func testChangeInFiatInput() async throws {
        let initialState = SendInputState.zero(
            status: .ready,
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            feeRelayerContext: feeContext(),
            sendViaLinkSeed: nil
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeAmountInFiat(0.05),
            services: services
        )

        XCTAssertEqual(nextState.amountInToken, 0.004)
        XCTAssertEqual(nextState.amountInFiat, 0.05)
        XCTAssertEqual(nextState.status, .ready)
    }

    /// Change input in fiat to max
    ///
    /// Token: SOL
    func testChangeInFiatInputToMax() async throws {
        let initialState = SendInputState.zero(
            status: .ready,
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            feeRelayerContext: feeContext(),
            sendViaLinkSeed: nil
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeAmountInFiat(initialState.maxAmountInputInFiat),
            services: services
        )

        XCTAssertEqual(nextState.amountInToken, 0.03)
        XCTAssertEqual(nextState.amountInFiat, 0.375)
        XCTAssertEqual(nextState.status, .ready)
    }

    /// Change input in fiat to max
    ///
    /// Token: SOL
    func testChangeInFiatInputTooHigh() async throws {
        let initialState = SendInputState.zero(
            status: .ready,
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            feeRelayerContext: feeContext(),
            sendViaLinkSeed: nil
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeAmountInFiat(0.5),
            services: services
        )

        XCTAssertEqual(nextState.amountInToken, 0.04)
        XCTAssertEqual(nextState.amountInFiat, 0.5)
        XCTAssertEqual(nextState.status, .error(reason: .inputTooHigh))
    }
}
