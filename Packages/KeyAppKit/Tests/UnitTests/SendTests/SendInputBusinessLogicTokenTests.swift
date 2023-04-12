// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import NameService
import SolanaSwift
import XCTest
@testable import Send

class SendInputBusinessLogicTokenTests: XCTestCase {
    let defaultUserWalletState: UserWalletEnvironments = .init(
        wallets: [
            .nativeSolana(pubkey: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V", lamport: 30_000_000),
            .init(pubkey: "7cRd5jTqByhQVVEDdhzoANiD98JV2MW27b64tKLiRDaC", lamports: 1_000_000, supply: 0, token: .usdt),
        ],
        exchangeRate: ["SOL": .init(value: 12.5), "USDT": .init(value: 1.1)],
        tokens: [.nativeSolana]
    )

    let services: SendInputServices = .init(
        swapService: MockedSwapService(result: nil),
        feeService: SendFeeCalculatorImpl(feeRelayerCalculator: DefaultFreeRelayerCalculator()),
        solanaAPIClient: MockedSolanaAPIClient()
    )

    private func feeContext(currentUsage: Int = 0) -> FeeRelayerContext {
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
                amountUsed: 0,
                maxTokenAccountCreationAmount: 10000000,
                maxTokenAccountCreationCount: 30,
                //                tokenAccountCreationAmountUsed: 0,
                tokenAccountCreationCountUsed: 0
            )
        )
    }

    func testInitialize() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account _: String) async throws -> BufferInfo<T>? { nil }

            override func getTokenAccountsByOwner(
                pubkey _: String,
                params _: OwnerInfoParams?,
                configs _: RequestConfiguration?
            ) async throws -> [SolanaSwift.TokenAccount<AccountInfo>] {
                []
            }
        }

        let services: SendInputServices = .init(
            swapService: MockedSwapService(result: nil),
            feeService: SendFeeCalculatorImpl(feeRelayerCalculator: DefaultFreeRelayerCalculator()),
            solanaAPIClient: SolanaAPIClient()
        )

        let initialState = SendInputState.zero(
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            sendViaLinkSeed: nil
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .initialize(.init(feeRelayerContext: feeContext(currentUsage: 100))),
            services: services
        )

        XCTAssertEqual(nextState.fee.transaction, 5000)
        XCTAssertEqual(nextState.amountInToken, 0.0)
        XCTAssertEqual(nextState.amountInFiat, 0.0)
        XCTAssertEqual(nextState.status, .ready)
    }

    func testChangingToken() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account _: String) async throws -> BufferInfo<T>? { nil }

            override func getTokenAccountsByOwner(
                pubkey _: String,
                params _: OwnerInfoParams?,
                configs _: RequestConfiguration?
            ) async throws -> [SolanaSwift.TokenAccount<AccountInfo>] {
                []
            }
        }

        let services: SendInputServices = .init(
            swapService: MockedSwapService(result: nil),
            feeService: SendFeeCalculatorImpl(feeRelayerCalculator: DefaultFreeRelayerCalculator()),
            solanaAPIClient: SolanaAPIClient()
        )

        let initialState = SendInputState.zero(
            status: .ready,
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            recipientAdditionalInfo: .init(
                walletAccount: nil,
                splAccounts: []
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            feeRelayerContext: feeContext(),
            sendViaLinkSeed: nil
        )

        var nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeUserToken(.usdt),
            services: services
        )

        XCTAssertEqual(nextState.fee.transaction, 0)
        XCTAssertEqual(nextState.fee.accountBalances, 2_039_280)
        XCTAssertEqual(nextState.amountInToken, 0.0)
        XCTAssertEqual(nextState.amountInFiat, 0.0)
        XCTAssertEqual(nextState.status, .ready)

        nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: nextState,
            action: .changeAmountInToken(1),
            services: services
        )

        XCTAssertEqual(nextState.fee.transaction, 0)
        XCTAssertEqual(nextState.fee.accountBalances, 2_039_280)
        XCTAssertEqual(nextState.amountInToken, 1)
        XCTAssertEqual(nextState.amountInFiat, 1.1)
        XCTAssertEqual(nextState.status, .ready)
    }

    func testChangingTokenNoFee() async throws {
        class SolanaAPIClient: MockedSolanaAPIClient {
            override func getAccountInfo<T: BufferLayout>(account _: String) async throws -> BufferInfo<T>? { nil }

            override func getTokenAccountsByOwner(
                pubkey _: String,
                params _: OwnerInfoParams?,
                configs _: RequestConfiguration?
            ) async throws -> [SolanaSwift.TokenAccount<AccountInfo>] {
                [
                    .init(
                        pubkey: "7cRd5jTqByhQVVEDdhzoANiD98JV2MW27b64tKLiRDaC",
                        account: .init(
                            lamports: 100_000,
                            owner: TokenProgram.id.base58EncodedString,
                            data: AccountInfo(
                                mint: try PublicKey(string: Token.usdc.address),
                                owner: try PublicKey(string: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V"),
                                lamports: 50_000_000,
                                delegateOption: 0,
                                isInitialized: false,
                                isFrozen: false,
                                state: 0,
                                isNativeOption: 0,
                                isNativeRaw: 0,
                                isNative: false,
                                delegatedAmount: 0,
                                closeAuthorityOption: 0
                            ),
                            executable: false,
                            rentEpoch: 0
                        )
                    ),
                ]
            }
        }

        let services: SendInputServices = .init(
            swapService: MockedSwapService(result: nil),
            feeService: SendFeeCalculatorImpl(feeRelayerCalculator: DefaultFreeRelayerCalculator()),
            solanaAPIClient: SolanaAPIClient()
        )

        let initialState = SendInputState.zero(
            status: .requiredInitialize,
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            recipientAdditionalInfo: .init(
                walletAccount: nil,
                splAccounts: []
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState,
            sendViaLinkSeed: nil
        )

        var nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .initialize(.init(feeRelayerContext: feeContext(currentUsage: 0))),
            services: services
        )

        nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: nextState,
            action: .changeUserToken(.usdt),
            services: services
        )

        XCTAssertEqual(nextState.fee.transaction, 0)
        XCTAssertEqual(nextState.fee.accountBalances, 0)
        XCTAssertEqual(nextState.amountInToken, 0.0)
        XCTAssertEqual(nextState.amountInFiat, 0.0)
        XCTAssertEqual(nextState.status, .ready)

        nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: nextState,
            action: .changeAmountInToken(1),
            services: services
        )

        XCTAssertEqual(nextState.fee.transaction, 0)
        XCTAssertEqual(nextState.fee.accountBalances, 0)
        XCTAssertEqual(nextState.amountInToken, 1)
        XCTAssertEqual(nextState.amountInFiat, 1.1)
        XCTAssertEqual(nextState.status, .ready)
    }
}
