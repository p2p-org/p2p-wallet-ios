//
//  File.swift
//  
//
//  Created by Chung Tran on 16/02/2022.
//

import XCTest
import SolanaSwift
@testable import FeeRelayerSwift
import OrcaSwapSwift

class RelaySendTests: RelayTests {
//    func testRelaySendNativeSOL() async throws {
//        try await runRelaySendNativeSOL(testsInfo.relaySendNativeSOL!)
//    }
//
//    func testUSDTTransfer() async throws {
//        try await runRelaySendSPLToken(testsInfo.usdtTransfer!)
//    }
//
//    func testUSDTBackTransfer() async throws {
//        try await runRelaySendSPLToken(testsInfo.usdtBackTransfer!)
//    }
//
//    func testUSDTTransferToNonCreatedToken() async throws {
//        try await runRelaySendSPLToken(testsInfo.usdtTransferToNonCreatedToken!)
//    }
//
//    // MARK: - Helpers
//    private func runRelaySendNativeSOL(_ test: RelayTransferNativeSOLTestInfo) async throws {
//        let feeRelayerAPIClient = try loadTest(test)
//
//        let payingToken = FeeRelayer.Relay.TokenInfo(
//            address: test.payingTokenAddress,
//            mint: test.payingTokenMint
//        )
//
//        let feePayer = try await feeRelayerAPIClient.getFeePayerPubkey()//.toBlocking().first()!
//
//        let preparedTransaction = try solanaClient.prepareSendingNativeSOL(
//            to: test.destination,
//            amount: test.inputAmount,
//            feePayer: try PublicKey(string: feePayer)
//        ).toBlocking().first()!
//
//        XCTAssertEqual(preparedTransaction.expectedFee.total, test.expectedFee)
//
//        let signature = try relayService.topUpAndRelayTransaction(
//            preparedTransaction: preparedTransaction,
//            payingFeeToken: payingToken
//        ).toBlocking().first()
//        print(signature ?? "Nothing")
//    }
//
//    private func runRelaySendSPLToken(_ test: RelayTransferTestInfo) async throws {
//        let feeRelayerAPIClient = try loadTest(test)
//
//        let payingToken = FeeRelayer.Relay.TokenInfo(
//            address: test.payingTokenAddress,
//            mint: test.payingTokenMint
//        )
//
//        let feePayer = try await feeRelayerAPIClient.getFeePayerPubkey()//.toBlocking().first()!
//
//        let preparedTransaction = try solanaClient.prepareSendingSPLTokens(
//            mintAddress: test.mint,
//            decimals: 6,
//            from: test.sourceTokenAddress,
//            to: test.destinationAddress,
//            amount: 100,
//            feePayer: try PublicKey(string: feePayer),
//            transferChecked: true
//        ).toBlocking().first()!.preparedTransaction
//
//        XCTAssertEqual(preparedTransaction.expectedFee.total, test.expectedFee)
//
//        let signature = try relayService.topUpAndRelayTransaction(
//            preparedTransaction: preparedTransaction,
//            payingFeeToken: payingToken
//        ).toBlocking().first()
//        print(signature ?? "Nothing")
//    }
}
