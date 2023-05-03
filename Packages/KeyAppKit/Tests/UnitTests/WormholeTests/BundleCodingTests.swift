@testable import Wormhole
import XCTest

final class BundleCodingTests: XCTestCase {
    func testDecodeBundle1() throws {
        let json = """
            {"bundle_id":"9341f85c-c0b3-41ef-a888-9b2e00c447f4","user_wallet":"0xc77b22884e476ddf4c60fadc7605e74bddaba426","recipient":"3f1jB3pieiLw1XstjrAG5pRC1xGaF3XTpjmhNMMmyGJA", "result_amount": {"amount": "0", "usd_amount": "0", "chain": "Ethereum", "token": "Ethereum"}, "token":"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48","with_compensations":{"no":"gas_price_too_high"},"expires_at":1677678054,"transactions":["0xf867108506fc23ac0083011b2094a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4880b844095ea7b30000000000000000000000003ee18b2214aff97000d974cf647e7c347e8fa58500000000000000000000000000000000000000000000000000000000000f4240","0xf8e7118506fc23ac008301f274943ee18b2214aff97000d974cf647e7c347e8fa58580b8c40f5287b0000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000000000f4240000000000000000000000000000000000000000000000000000000000000000177067d8ef004fb9f485613b5d0b482303968e0359f2ef38701d65547fc40d0ef0000000000000000000000000000000000000000000000000000000000200b200000000000000000000000000000000000000000000000000000000000007e32"],"signatures":null,"fees":{"gas":{"amount":"11131798148183700","usd_amount":"16.6976131", "chain": "Ethereum", "token": "Ethereum"},"arbiter":{"amount":"2000000","usd_amount":"2", "chain": "Ethereum", "token": "Ethereum"},"create_account":{"amount":"41438","usd_amount":"0.0414381696","chain": "Ethereum", "token": "Ethereum"}}}
        """
        guard let data = json.data(using: .utf8) else {
            XCTExpectFailure("Preparing data error")
            return
        }

        let bundle = try JSONDecoder().decode(WormholeBundle.self, from: data)
        let encodedBundle = try JSONEncoder().encode(bundle)
        let decodedBundle = try JSONDecoder().decode(WormholeBundle.self, from: encodedBundle)
        
        XCTAssertEqual(decodedBundle, bundle)
    }

    func testDecodeBundle2() throws {
        let json = """
            {"bundle_id":"9341f85c-c0b3-41ef-a888-9b2e00c447f4","user_wallet":"0xc77b22884e476ddf4c60fadc7605e74bddaba426","recipient":"3f1jB3pieiLw1XstjrAG5pRC1xGaF3XTpjmhNMMmyGJA","result_amount": {"amount": "11223120", "usd_amount": "0.32113", "chain": "Solana", "token": "Solana" },"token":"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48","with_compensations":"yes","expires_at":1677678054,"transactions":["0xf867108506fc23ac0083011b2094a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4880b844095ea7b30000000000000000000000003ee18b2214aff97000d974cf647e7c347e8fa58500000000000000000000000000000000000000000000000000000000000f4240","0xf8e7118506fc23ac008301f274943ee18b2214aff97000d974cf647e7c347e8fa58580b8c40f5287b0000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000000000f4240000000000000000000000000000000000000000000000000000000000000000177067d8ef004fb9f485613b5d0b482303968e0359f2ef38701d65547fc40d0ef0000000000000000000000000000000000000000000000000000000000200b200000000000000000000000000000000000000000000000000000000000007e32"],"signatures":null,"fees":{"gas":{"amount":"11131798148183700","usd_amount":"16.6976131", "chain": "Solana", "token": "Solana"},"arbiter":{"amount":"2000000","usd_amount":"2", "chain": "Solana", "token": "Solana"},"create_account":{"amount":"41438","usd_amount":"0.0414381696", "chain": "Solana", "token": "Solana"}}}
        """
        guard let data = json.data(using: .utf8) else {
            XCTExpectFailure("Preparing data error")
            return
        }

        let bundle = try JSONDecoder().decode(WormholeBundle.self, from: data)
        let encodedBundle = try JSONEncoder().encode(bundle)
        let decodedBundle = try JSONDecoder().decode(WormholeBundle.self, from: encodedBundle)

        XCTAssertEqual(decodedBundle, bundle)
    }
}
