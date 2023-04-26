@testable import KeyAppBusiness
import XCTest

import Combine
import KeyAppKitCore
import SolanaPricesAPIs
import SolanaSwift
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

        let pricesNetworkManager = MockPricesNetworkManager { _ in
            ""
        }
        let priceService = EthereumPriceService(api: CoinGeckoPricesAPI(pricesNetworkManager: pricesNetworkManager))

        let service = EthereumAccountsServiceImpl(
            address: "0x5Eaa9C2000a76DA450E9d1dAF44bb532337586EC",
            web3: web3,
            ethereumTokenRepository: EthereumTokensRepository(web3: web3),
            priceService: priceService,
            fiat: "usd",
            errorObservable: MockErrorObservable()
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
