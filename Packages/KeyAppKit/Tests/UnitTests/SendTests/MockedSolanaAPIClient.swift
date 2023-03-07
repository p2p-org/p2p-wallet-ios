// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

class MockedSolanaAPIClient: SolanaAPIClient {
    var endpoint: SolanaSwift.APIEndPoint { fatalError() }

    func getAccountInfo<T: BufferLayout>(
        account _: String
    ) async throws -> BufferInfo<T>? { fatalError("getAccountInfo(account:) has not been implemented") }

    func getBalance(
        account _: String,
        commitment _: Commitment?
    ) async throws -> UInt64 { fatalError("getBalance(account:commitment:) has not been implemented") }

    func getBlockCommitment(
        block _: UInt64
    ) async throws -> BlockCommitment { fatalError("getBlockCommitment(block:) has not been implemented") }

    func getBlockTime(
        block _: UInt64
    ) async throws -> Date { fatalError("getBlockTime(block:) has not been implemented") }

    func getClusterNodes() async throws -> [ClusterNodes] { fatalError("getClusterNodes() has not been implemented") }

    func getBlockHeight() async throws -> UInt64 { fatalError("getBlockHeight() has not been implemented") }

    func getConfirmedBlocksWithLimit(
        startSlot _: UInt64,
        limit _: UInt64
    ) async throws -> [UInt64] { fatalError("getConfirmedBlocksWithLimit(startSlot:limit:) has not been implemented") }

    func getConfirmedBlock(
        slot _: UInt64,
        encoding _: String
    ) async throws -> ConfirmedBlock { fatalError("getConfirmedBlock(slot:encoding:) has not been implemented") }

    func getConfirmedSignaturesForAddress(
        account _: String,
        startSlot _: UInt64,
        endSlot _: UInt64
    ) async throws
    -> [String] {
        fatalError("getConfirmedSignaturesForAddress(account:startSlot:endSlot:) has not been implemented")
    }

    func getEpochInfo(
        commitment _: Commitment?
    ) async throws -> EpochInfo { fatalError("getEpochInfo(commitment:) has not been implemented") }

    func getFees(
        commitment _: Commitment?
    ) async throws -> Fee { fatalError("getFees(commitment:) has not been implemented") }

    func getMinimumBalanceForRentExemption(
        dataLength _: UInt64,
        commitment _: Commitment?
    ) async throws
    -> UInt64 { fatalError("getMinimumBalanceForRentExemption(dataLength:commitment:) has not been implemented") }

    func getSignatureStatuses(
        signatures _: [String],
        configs _: RequestConfiguration?
    ) async throws
    -> [SignatureStatus?] { fatalError("getSignatureStatuses(signatures:configs:) has not been implemented") }

    func getSignatureStatus(
        signature _: String,
        configs _: RequestConfiguration?
    ) async throws -> SignatureStatus { fatalError("getSignatureStatus(signature:configs:) has not been implemented") }

    func getTokenAccountBalance(
        pubkey _: String,
        commitment _: Commitment?
    ) async throws
    -> TokenAccountBalance { fatalError("getTokenAccountBalance(pubkey:commitment:) has not been implemented") }

    func getTokenAccountsByDelegate(
        pubkey _: String,
        mint _: String?,
        programId _: String?,
        configs _: RequestConfiguration?
    ) async throws
    -> [TokenAccount<AccountInfo>] {
        fatalError("getTokenAccountsByDelegate(pubkey:mint:programId:configs:) has not been implemented")
    }

    func getTokenAccountsByOwner(
        pubkey _: String,
        params _: OwnerInfoParams?,
        configs _: RequestConfiguration?
    ) async throws
    -> [TokenAccount<AccountInfo>] {
        fatalError("getTokenAccountsByOwner(pubkey:params:configs:) has not been implemented")
    }

    func getTokenLargestAccounts(
        pubkey _: String,
        commitment _: Commitment?
    ) async throws
    -> [TokenAmount] { fatalError("getTokenLargestAccounts(pubkey:commitment:) has not been implemented") }

    func getTokenSupply(
        pubkey _: String,
        commitment _: Commitment?
    ) async throws -> TokenAmount { fatalError("getTokenSupply(pubkey:commitment:) has not been implemented") }

    func getVersion() async throws -> Version { fatalError("getVersion() has not been implemented") }

    func getVoteAccounts(
        commitment _: Commitment?
    ) async throws -> VoteAccounts { fatalError("getVoteAccounts(commitment:) has not been implemented") }

    func minimumLedgerSlot() async throws -> UInt64 { fatalError("minimumLedgerSlot() has not been implemented") }

    func requestAirdrop(
        account _: String,
        lamports _: UInt64,
        commitment _: Commitment?
    ) async throws -> String { fatalError("requestAirdrop(account:lamports:commitment:) has not been implemented") }

    func sendTransaction(
        transaction _: String,
        configs _: RequestConfiguration
    ) async throws -> TransactionID { fatalError("sendTransaction(transaction:configs:) has not been implemented") }

    func simulateTransaction(
        transaction _: String,
        configs _: RequestConfiguration
    ) async throws
    -> SimulationResult { fatalError("simulateTransaction(transaction:configs:) has not been implemented") }

    func setLogFilter(
        filter _: String
    ) async throws -> String? { fatalError("setLogFilter(filter:) has not been implemented") }

    func validatorExit() async throws -> Bool { fatalError("validatorExit() has not been implemented") }

    func getMultipleAccounts<T: BufferLayout>(
        pubkeys _: [String]
    ) async throws -> [BufferInfo<T>] { fatalError("getMultipleAccounts(pubkeys:) has not been implemented") }

    func observeSignatureStatus(
        signature _: String,
        timeout _: Int,
        delay _: Int
    )
    -> AsyncStream<TransactionStatus> {
        fatalError("observeSignatureStatus(signature:timeout:delay:) has not been implemented")
    }

    func getRecentBlockhash(
        commitment _: Commitment?
    ) async throws -> String { fatalError("getRecentBlockhash(commitment:) has not been implemented") }

    func getSignaturesForAddress(
        address _: String,
        configs _: RequestConfiguration?
    ) async throws
    -> [SignatureInfo] { fatalError("getSignaturesForAddress(address:configs:) has not been implemented") }

    func getTransaction(
        signature _: String,
        commitment _: Commitment?
    ) async throws -> TransactionInfo? { fatalError("getTransaction(signature:commitment:) has not been implemented") }

    func request<Entity: Decodable>(
        method _: String,
        params _: [Encodable]
    ) async throws -> Entity { fatalError("request(method:params:) has not been implemented") }

    func batchRequest(
        with _: [JSONRPCRequestEncoder.RequestType]
    ) async throws
    -> [AnyResponse<JSONRPCRequestEncoder.RequestType.Entity>] {
        fatalError("batchRequest(with:) has not been implemented")
    }

    func batchRequest<Entity: Decodable>(
        method _: String,
        params _: [[Encodable]]
    ) async throws -> [Entity?] { fatalError("batchRequest(method:params:) has not been implemented") }

    func getRecentPerformanceSamples(
        limit _: [UInt]
    ) async throws -> [PerfomanceSamples] { fatalError("getRecentPerformanceSamples(limit:) has not been implemented") }
}
