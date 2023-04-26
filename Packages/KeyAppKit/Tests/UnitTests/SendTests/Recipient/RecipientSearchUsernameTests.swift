// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppKitCore
import NameService
@testable import Send
import SolanaSwift
import XCTest

class RecipientSearchUsernameTests: XCTestCase {
    let defaultInitialWalletEnvs: UserWalletEnvironments = .init(
        wallets: [
            Wallet(
                pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh21",
                lamports: 5_000_000,
                token: .nativeSolana
            ),
            Wallet(
                pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh22",
                lamports: 5_000_000,
                token: .usdc
            ),
            Wallet(
                pubkey: "GGjRx5zJrtCKfXuhDbEkEnaT2uQ7NxbUm8pn224cRh23",
                lamports: 5_000_000,
                token: .usdt
            ),
        ],
        ethereumAccount: nil,
        exchangeRate: [:],
        tokens: [.nativeSolana, .usdc, .usdt]
    )

    let defaultSolanaClient: SolanaAPIClient = JSONRPCAPIClient(
        endpoint: .init(
            address: "https://api.mainnet-beta.solana.com",
            network: .mainnetBeta
        )
    )

    func testNameService() async throws {
        class TestMockNameService: MockedNameService {
            override func getOwners(_: String) async throws -> [NameRecord] {
                [
                    .init(
                        name: "kirill.key",
                        parent: "6vQGsE2pqtnKbeWWESzGtYT5BRCQUmaB7Lq8vw4AuHG6",
                        owner: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                        ownerClass: "11111111111111111111111111111111"
                    ),
                    .init(
                        name: "kirill.p2p.sol",
                        parent: "HSqVcxpDaZzwkHxreLisDtR9bQsLaTCMzMATFVhDoeNe",
                        owner: "C3csVsasSxQFX1f8EuihZCx9nu6HK2uujRNACxWB7SzS",
                        ownerClass: "11111111111111111111111111111111"
                    ),
                ]
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: TestMockNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "kirill",
            env: defaultInitialWalletEnvs,
            preChosenToken: nil
        )

        XCTAssertEqual(result, .ok([
            .init(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .username(name: "kirill", domain: "key"),
                attributes: [.funds]
            ),
            .init(
                address: "C3csVsasSxQFX1f8EuihZCx9nu6HK2uujRNACxWB7SzS",
                category: .username(name: "kirill.p2p", domain: "sol"),
                attributes: [.funds]
            ),
        ]))
    }

    func testNameServiceNoName() async throws {
        class TestMockNameService: MockedNameService {
            override func getOwners(_: String) async throws -> [NameRecord] {
                [
                    .init(
                        name: nil,
                        parent: "6vQGsE2pqtnKbeWWESzGtYT5BRCQUmaB7Lq8vw4AuHG6",
                        owner: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                        ownerClass: "11111111111111111111111111111111"
                    ),
                    .init(
                        name: "kirill.p2p.sol",
                        parent: "YSqVcxpDaZzwkHxreLisDtR9bQsLaTCMzMATFVhDoeNe",
                        owner: "T3csVsasSxQFX1f8EuihZCx9nu6HK2uujRNACxWB7SzS",
                        ownerClass: "11111111111111111111111111111111"
                    ),
                    .init(
                        name: nil,
                        parent: "HSqVcxpDaZzwkHxreLisDtR9bQsLaTCMzMATFVhDoeNe",
                        owner: "C3csVsasSxQFX1f8EuihZCx9nu6HK2uujRNACxWB7SzS",
                        ownerClass: "11111111111111111111111111111111"
                    ),
                ]
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: TestMockNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "kirill",
            env: defaultInitialWalletEnvs,
            preChosenToken: nil
        )

        XCTAssertEqual(result, .ok([
            .init(
                address: "T3csVsasSxQFX1f8EuihZCx9nu6HK2uujRNACxWB7SzS",
                category: .username(name: "kirill.p2p", domain: "sol"),
                attributes: [.funds]
            ),
            .init(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .solanaAddress,
                attributes: [.funds]
            ),
            .init(
                address: "C3csVsasSxQFX1f8EuihZCx9nu6HK2uujRNACxWB7SzS",
                category: .solanaAddress,
                attributes: [.funds]
            ),
        ]))
    }

    func testNameServiceError() async throws {
        class TestMockNameService: MockedNameService {
            static let error = NSError(domain: "Network", code: 404)

            override func getOwners(_: String) async throws -> [NameRecord] {
                throw Self.error
            }
        }

        let service = RecipientSearchServiceImpl(
            nameService: TestMockNameService(),
            solanaClient: defaultSolanaClient,
            swapService: MockedSwapService(result: nil)
        )

        let result = await service.search(
            input: "kirill",
            env: defaultInitialWalletEnvs,
            preChosenToken: nil
        )

        XCTAssertEqual(result, .nameServiceError(TestMockNameService.error))
    }
}
