import XCTest
@testable import Solend

class SolendMathTests: XCTestCase {
    func testReward() {
        let rewards = SolendMath.reward(
            marketInfos: [
                .init(symbol: "USDT", currentSupply: "0", depositLimit: "0", supplyInterest: "3.0521312"),
                .init(symbol: "SOL", currentSupply: "0", depositLimit: "0", supplyInterest: "2.4312123"),
                .init(symbol: "USDC", currentSupply: "0", depositLimit: "0", supplyInterest: "2.21321312"),
                .init(symbol: "ETH", currentSupply: "0", depositLimit: "0", supplyInterest: "0.78321312"),
                .init(symbol: "BTC", currentSupply: "0", depositLimit: "0", supplyInterest: "0.042321321"),
            ],
            userDeposits: [
                .init(symbol: "USDT", depositedAmount: "3096.19231"),
                .init(symbol: "SOL", depositedAmount: "23.8112"),
            ]
        )
        
        print(rewards)
    }
}
