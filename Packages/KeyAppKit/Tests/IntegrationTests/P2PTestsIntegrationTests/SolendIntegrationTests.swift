import XCTest
@testable import P2PSwift

class SolendIntegrationTests: XCTestCase {
    // func testGetSolendMarketInfo() async throws {
    //     let solend = SolendFFIWrapper()
    //     let result = try await solend.getCollateralAccounts(
    //         rpcURL: "https://api.mainnet-beta.solana.com",
    //         owner: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7"
    //     )
    //
    //     XCTAssertEqual(result.count, 2)
    // }
    //
    // func testGetMarketInfo() async throws {
    //     let solend = SolendFFIWrapper()
    //     let result = try await solend.getMarketInfo(symbols: ["USDT", "USDC"], pool: "main")
    //     print(result)
    //     // XCTAssertEqual(result.count, 2)
    // }
    //
    // func testGetUserDeposit() async throws {
    //     let solend = SolendFFIWrapper()
    //     let result = try await solend.getUserDeposits(
    //         owner: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7",
    //         poolAddress: "4UpD2fh7xH3VP9QQaXtsS1YY3bxzWhtfpks7FatyKvdY"
    //     )
    //     XCTAssertEqual(result.count, 2)
    // }
    //
    // func testGetUserDepositBySymbol() async throws {
    //     let solend = SolendFFIWrapper()
    //     let result = try await solend.getUserDepositBySymbol(
    //         owner: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7",
    //         symbol: "USDC",
    //         poolAddress: "4UpD2fh7xH3VP9QQaXtsS1YY3bxzWhtfpks7FatyKvdY"
    //     )
    //     XCTAssertEqual(result.symbol, "USDC")
    // }
    //
    // func testGetDepositFee() async throws {
    //     let solend = SolendFFIWrapper()
    //     let result = try await solend.getDepositFee(
    //         rpcUrl: "https://api.mainnet-beta.solana.com",
    //         owner: "GccETn3yYfwVmgmfvcggsEAUKd5zqFTiKF5skj2bGYU7",
    //         tokenAmount: 100_000,
    //         tokenSymbol: "USDC"
    //     )
    //     XCTAssertEqual(result.fee, 5000)
    // }
    //
    // func testCreateDepositTransaction() async throws {
    //     let solend = SolendFFIWrapper()
    //     let result = try await solend.createDepositTransaction(
    //         solanaRpcUrl: "https://api.mainnet-beta.solana.com",
    //         relayProgramId: "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT",
    //         amount: 10,
    //         symbol: "USDC",
    //         ownerAddress: "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu",
    //         environment: .production,
    //         lendingMarketAddress: "7RCz8wb6WXxUhAigok9ttgrVgDFFFbibcirECzWSBauM",
    //         blockHash: "78Ms4zEJkgbCyPjsdn7UyXyttUjVMMHogd1ZVqxPrRfk",
    //         freeTransactionsCount: 3,
    //         needToUseRelay: true,
    //         payInFeeToken: .init(
    //             senderAccount: "4tqJeGMJpaBdaWwbmREsQCFTjWqscfjUGeHuq8buGvTZ",
    //             recipientAccount: "BCxDhVmRK4aGVhNyF6fnTvAC8QBwZiTGXMnxroCcskdu",
    //             mint: "FANTafPFBAt93BNJVpdu25pGPmca3RfwdsDsRrT3LX1r",
    //             authority: "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu",
    //             exchangeRate: 0.1,
    //             decimals: 2
    //         ),
    //         feePayerAddress: "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT"
    //     )
    //
    //     XCTAssertEqual(result.count, 1)
    // }
    //
    // func testCreateWithdrawTransaction() async throws {
    //     let solend = SolendFFIWrapper()
    //     let result = try await solend.createWithdrawTransaction(
    //         solanaRpcUrl: "https://api.mainnet-beta.solana.com",
    //         relayProgramId: "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT",
    //         amount: 10,
    //         symbol: "USDC",
    //         ownerAddress: "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu",
    //         environment: .production,
    //         lendingMarketAddress: "7RCz8wb6WXxUhAigok9ttgrVgDFFFbibcirECzWSBauM",
    //         blockHash: "78Ms4zEJkgbCyPjsdn7UyXyttUjVMMHogd1ZVqxPrRfk",
    //         freeTransactionsCount: 3,
    //         needToUseRelay: true,
    //         payInFeeToken: .init(
    //             senderAccount: "4tqJeGMJpaBdaWwbmREsQCFTjWqscfjUGeHuq8buGvTZ",
    //             recipientAccount: "BCxDhVmRK4aGVhNyF6fnTvAC8QBwZiTGXMnxroCcskdu",
    //             mint: "FANTafPFBAt93BNJVpdu25pGPmca3RfwdsDsRrT3LX1r",
    //             authority: "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu",
    //             exchangeRate: 0.1,
    //             decimals: 2
    //         ),
    //         feePayerAddress: "FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT"
    //     )
    //
    //     XCTAssertEqual(result.count, 1)
    // }
}
