import XCTest
@testable import KeyAppBusiness

import Combine
import KeyAppKitCore
import SolanaSwift
import TokenService
import Web3

final class EthereumAccountsServiceTests: XCTestCase {
    // Ensure 30 seconds updating
    func testMonitoringByTimer() async throws {
        let web3Provider = MockWeb3Provider()
        try web3Provider.addStub(method: "eth_getBalance", result: EthereumQuantity(integerLiteral: 0))
        try web3Provider.addStub(
            method: "alchemy_getTokenBalances",
            result: EthereumTokenBalances(
                address: .init(hex: "0x5Eaa9C2000a76DA450E9d1dAF44bb532337586EC", eip55: true),
                tokenBalances: [],
                pageKey: nil
            )
        )

        let web3 = Web3(provider: web3Provider)
        let priceService = MockJupiterPriceService()
        let keyAppTokenProvider = MockKeyAppTokenProvider()

        let service = EthereumAccountsService(
            address: "0x5Eaa9C2000a76DA450E9d1dAF44bb532337586EC",
            web3: web3,
            ethereumTokenRepository: EthereumTokensRepository(provider: keyAppTokenProvider),
            priceService: priceService,
            fiat: "usd",
            errorObservable: MockErrorObservable(),
            enable: true
        )

        // After 1 second
        try await Helper.sleep(seconds: 1)
        XCTAssertEqual(service.state.value.native?.balance, 0)

        // After 28 second
        try await Helper.sleep(seconds: 27)
        XCTAssertEqual(service.state.value.native?.balance, 0)

        try web3Provider.addStub(method: "eth_getBalance", result: EthereumQuantity(integerLiteral: 1000))

        // After 33 second
        try await Helper.sleep(seconds: 5)
        XCTAssertEqual(service.state.value.native?.balance, 1000)
    }
}
