//
//  JupiterSwapBusinessLogicHelperSendToBlockchain.swift
//  
//
//  Created by Chung Tran on 18/03/2023.
//

import XCTest
import SolanaSwift
import Jupiter
import Swap
import Combine
import Task_retrying

final class JupiterSwapBusinessLogicHelperSendToBlockchainTests: XCTestCase {
    private var mockJupiterAPI: MockJupiterAPI!
    private var mockSolanaAPIClient: MockSolanaAPIClient!
    var account: KeyPair!
    var route: Route!
    let mockedSwapTransactionId = "mockedSwapTransactionId"
    
    override func setUpWithError() throws {
        mockJupiterAPI = MockJupiterAPI()
        mockSolanaAPIClient = MockSolanaAPIClient(
            mockedResults: [
                .success(mockedSwapTransactionId)
            ]
        )
        account = try KeyPair()
        route = .route(marketInfos: [.marketInfo(index: 1), .marketInfo(index: 2)])
    }
    
    override func tearDown() async throws {
        mockJupiterAPI = nil
        mockSolanaAPIClient = nil
    }
    
    /// Test sending a transaction to the blockchain successfully.
    func testSendToBlockchainSuccess() async throws {
        // when
        let transactionId = try await JupiterSwapBusinessLogicHelper.sendToBlockchain(
            account: account,
            swapTransaction: mockedSwapTransactionId,
            route: route,
            jupiterClient: mockJupiterAPI,
            solanaAPIClient: mockSolanaAPIClient
        )
        
        // then
        XCTAssertEqual(transactionId, mockedSwapTransactionId)
    }
    
    /// Test sending a transaction to the blockchain with a retryable error, then throw when error is not retryable.
    func testSendToBlockchainThrowsNonRetriableError() async throws {
        // given
        mockJupiterAPI = MockJupiterAPI()
        mockSolanaAPIClient = .init(
            mockedResults: [
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.invalidAPIURL) // non-retriable error
            ]
        )
        
        // when
        var error: Error?
        do {
            let _ = try await JupiterSwapBusinessLogicHelper.sendToBlockchain(
                account: account,
                swapTransaction: mockedSwapTransactionId,
                route: route,
                jupiterClient: mockJupiterAPI,
                solanaAPIClient: mockSolanaAPIClient
            )
        } catch let testError {
            error = testError
        }
        
        // then
        XCTAssertEqual(APIClientError.invalidAPIURL, error as? APIClientError)
    }
    
    /// Test sending a transaction to the blockchain with a retryable error, then succeeding on retry.
    func testSendToBlockchainBlockhashNotFoundThenSuccess() async throws {
        // given
        mockJupiterAPI = MockJupiterAPI()
        mockSolanaAPIClient = .init(
            mockedResults: [
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.invalidTimestamp),
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.invalidTimestamp),
                .failure(APIClientError.blockhashNotFound),
                .success(mockedSwapTransactionId)
            ]
        )
        
        // when
        let transactionId = try await JupiterSwapBusinessLogicHelper.sendToBlockchain(
            account: account,
            swapTransaction: nil,
            route: route,
            jupiterClient: mockJupiterAPI,
            solanaAPIClient: mockSolanaAPIClient
        )
        
        // then
        XCTAssertEqual(transactionId, mockedSwapTransactionId)
    }
    
    /// Test sending a transaction to the blockchain with 6 retryable errors, then failing due to exceededMaxRetryCount.
    func testSendToBlockchainRetryableErrorExceededMaxRetryCount() async throws {
        // given
        mockSolanaAPIClient = .init(
            mockedResults: [
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.invalidTimestamp),
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.invalidTimestamp),
                .failure(JupiterError.invalidResponse),
                .failure(APIClientError.blockhashNotFound),
                .success(mockedSwapTransactionId)
            ]
        )
        
        // when
        var error: Error?
        do {
            let _ = try await JupiterSwapBusinessLogicHelper.sendToBlockchain(
                account: account,
                swapTransaction: mockedSwapTransactionId,
                route: route,
                jupiterClient: mockJupiterAPI,
                solanaAPIClient: mockSolanaAPIClient
            )
        } catch let testError {
            error = testError
        }
        
        // then
        XCTAssertEqual(TaskRetryingError.exceededMaxRetryCount, error as? TaskRetryingError)
    }
    
    /// Test sending a transaction to the blockchain with 3 retryable errors, then failing due to timedout.
    func testSendToBlockchainRetryableErrors() async throws {
        // given
        mockSolanaAPIClient = .init(
            mockedResults: [
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.blockhashNotFound),
                .failure(APIClientError.blockhashNotFound),
                .success(MockSolanaAPIClient.delayingFlagPrefix + "2_000_000_000"), // 2 secs
                .success(mockedSwapTransactionId)
            ]
        )
        
        // when
        var error: Error?
        do {
            let _ = try await JupiterSwapBusinessLogicHelper.sendToBlockchain(
                account: account,
                swapTransaction: mockedSwapTransactionId,
                route: route,
                jupiterClient: mockJupiterAPI,
                solanaAPIClient: mockSolanaAPIClient,
                timeOutInSeconds: 1
            )
        } catch let testError {
            error = testError
        }
        
        // then
        XCTAssertEqual(TaskRetryingError.timedOut, error as? TaskRetryingError)
    }
}

// MARK: - Helpers

private class MockJupiterAPI: MockJupiterAPIBase {
    override func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        asLegacyTransaction: Bool?,
        computeUnitPriceMicroLamports: Int?,
        destinationWallet: String?
    ) async throws -> String? {
        // Here, you could write your own implementation of how this method should behave during testing
        // For example, you could return a pre-defined string or throw a custom error
        
        // For the sake of simplicity, we'll just return the injected mocked response string
        "AgHBJTmqzU8iQAKWKeR/8YoUPCuaoWDRPvHnKuh4ZAyyJJ6rSsUO4EvUdmJ1h2H9b+yeL+CFdbeDWUh1YS/KdgsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAIAAgcEhDK86KdYVB1Pjs1JjKmPK6g9GAZa56V/jBPUb8rFpqKQw9EFK9Fj55SNpr+Hz9vkVpgT7w0sEDu2/Tw0PHaaGEbtKyFp3KxODcjxNK4W2DHFN7Ha7phaxzQ81WGIslAjFIwjF04y2F7VDRW+eTT8iRda0hjuzREFw+SiK58iEOgrFvHh3LzHrokvQuQWYMGkB11fhD71u6xrkYGcxUAvAwZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAAAEedUt7b9rxezQnYRTSjSupZdQQ7Nv0CskZQu1hENZXFT4EV4IzBWhu3FRZB4z7zvsBFHOfx86dh9/tcWIB4z3AgUABQLAXBUABg8KAQILCgEHAggDCQQEBAwj5RfLl3rjrSoAAQAAAAIRAOgDAAAAAAAAuOYAAAAAAAAyAAAB8SK6ARd8JB0h7LJxdf1d0S1RAXc3LYUny5mAXvIOzloDkpOUAwEAmA=="
    }
}

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    static let delayingFlagPrefix = "delayingFlag"
    var mockedResults: [Result<String, Error>]
    var attempt = -1
    
    init(mockedResults: [Result<String, Error>]) {
        self.mockedResults = mockedResults
        super.init()
    }
    
    override func sendTransaction(transaction: String, configs: RequestConfiguration) async throws -> TransactionID {
        // Here, you could write your own implementation of how this method should behave during testing
        // For example, you could return a pre-defined transaction ID or throw a custom error
        
        // For the sake of simplicity, we'll just return the injected dummy transaction ID
        attempt += 1
        switch mockedResults[attempt] {
        case .success(let transactionId):
            if transactionId.starts(with: Self.delayingFlagPrefix) {
                try await Task.sleep(nanoseconds: UInt64(transactionId.replacingOccurrences(of: Self.delayingFlagPrefix, with: ""))!)
            }
            print("mocked send transaction success: \(transactionId)")
            return transactionId
        case .failure(let failure):
            print("mocked send transaction failure: \(failure)")
            throw failure
        }
    }
}

private extension APIClientError {
    static var blockhashNotFound: Self {
        .responseError(
            ResponseError(
                code: nil,
                message: "Transaction simulation failed: Blockhash not found",
                data: nil
            )
        )
    }
    
    static var invalidTimestamp: Self {
        .responseError(
            ResponseError(
                code: nil,
                message: "<dummy>custom program error: 0x1786",
                data: nil
            )
        )
    }
}
