import Foundation
@testable import SolanaSwift

class MockSolanaAPIClient: SolanaAPIClient {
    var endpoint: APIEndPoint {
        APIEndPoint.defaultEndpoints.first!
    }

    func getAccountInfo<T>(account: String) async throws -> BufferInfo<T>? where T: BufferLayout {
        switch account {
        case "BjUEdE292SLEq9mMeKtY3GXL6wirn7DqJPhrukCqAUua":
            return nil
        case "8Vu3KXjZJPUdUf7cRWR9ukXuahoV9vNU5ExEo52SNH4G":
            var binaryReader =
                BinaryReader(bytes: Data(
                    base64Encoded: "BoMQhhqYMn0FUFdNhEGKpuEMM1Ldqn/X9YFSzO6yOIdi/XalJxOwfrmp1jI9t6I30VBlnsq7A+waTZA0Mr2M+3GeHQcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                )!
                    .bytes)
            return .init(
                lamports: 2_039_280,
                owner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                data: try! AccountInfo(from: &binaryReader) as! T,
                executable: false,
                rentEpoch: 316
            )
        case "EFs4FuHmb3bbC4BUD4tu188x4k5UMmxPbm6PZQjDnxL6":
            var binaryReader =
                BinaryReader(bytes: Data(
                    base64Encoded: "BpuIV/6rgYT7aH9jRhjANdrEOdwa6ztVmKDwAAAAAAFi/XalJxOwfrmp1jI9t6I30VBlnsq7A+waTZA0Mr2M+8X0TbsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAADwHR8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                )!
                    .bytes)
            return .init(
                lamports: 3_144_487_605,
                owner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                data: try! AccountInfo(from: &binaryReader) as! T,
                executable: false,
                rentEpoch: 316
            )
        case "HVc47am8HPYgvkkCiFJzV6Q8qsJJKJUYT6o7ucd6ZYXY":
            return nil
        case "FdiTt7XQ94fGkgorywN1GuXqQzmURHCDgYtUutWRcy4q":
            var binaryReader =
                BinaryReader(bytes: Data(
                    base64Encoded: "BpuIV/6rgYT7aH9jRhjANdrEOdwa6ztVmKDwAAAAAAGVnOqUkPJVr6muuizyY38m7w+KGKPwmhy/esO7Llb6UB/ruyd7AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAADwHR8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                )!
                    .bytes)
            return .init(
                lamports: 562_102_267_325,
                owner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                data: try! AccountInfo(from: &binaryReader) as! T,
                executable: false,
                rentEpoch: 316
            )
        case "ErcxwkPgLdyoVL6j2SsekZ5iysPZEDRGfAggh282kQb8":
            var binaryReader =
                BinaryReader(bytes: Data(
                    base64Encoded: "DlY5XjyGAUOALpuUoCzG0E91/scqP7txUmg1XgzXzYlZ9QCnv3uHbULVucoY03CjVfA+0o2LoUEOuFZWBIqlfMNn0YsuAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                )!
                    .bytes)
            return .init(
                lamports: 2_039_280,
                owner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                data: try! AccountInfo(from: &binaryReader) as! T,
                executable: false,
                rentEpoch: 316
            )
        case "3YuhjsaohzpzEYAsonBQakYDj3VFWimhDn7bci8ERKTh":
            return nil
        case "4ijqHixcbzhxQbfJWAoPkvBhokBDRGtXyqVcMN8ywj8W":
            return nil
        default:
            fatalError()
        }
    }

    func getBalance(account _: String, commitment _: Commitment?) async throws -> UInt64 {
        fatalError()
    }

    func getBlockCommitment(block _: UInt64) async throws -> BlockCommitment {
        fatalError()
    }

    func getBlockTime(block _: UInt64) async throws -> Date {
        fatalError()
    }

    func getClusterNodes() async throws -> [ClusterNodes] {
        fatalError()
    }

    func getBlockHeight() async throws -> UInt64 {
        fatalError()
    }

    func getConfirmedBlocksWithLimit(startSlot _: UInt64, limit _: UInt64) async throws -> [UInt64] {
        fatalError()
    }

    func getConfirmedBlock(slot _: UInt64, encoding _: String) async throws -> ConfirmedBlock {
        fatalError()
    }

    func getConfirmedSignaturesForAddress(account _: String, startSlot _: UInt64,
                                          endSlot _: UInt64) async throws -> [String]
    {
        fatalError()
    }

    func getEpochInfo(commitment _: Commitment?) async throws -> EpochInfo {
        fatalError()
    }

    func getFees(commitment _: Commitment?) async throws -> Fee {
        .init(
            feeCalculator: .init(lamportsPerSignature: 5000),
            feeRateGovernor: nil,
            blockhash: "GwXLB5biQoCEGPB1auCSoob87GBkiN9bqF8R78nsdSFp",
            lastValidSlot: 136_873_719
        )
    }

    func getSignatureStatuses(signatures _: [String],
                              configs _: RequestConfiguration?) async throws -> [SignatureStatus?]
    {
        fatalError()
    }

    func getSignatureStatus(signature _: String, configs _: RequestConfiguration?) async throws -> SignatureStatus {
        fatalError()
    }

    func getTokenAccountBalance(pubkey _: String, commitment _: Commitment?) async throws -> TokenAccountBalance {
        fatalError()
    }

    func getTokenAccountsByDelegate(
        pubkey _: String,
        mint _: String?,
        programId _: String?,
        configs _: RequestConfiguration?
    ) async throws -> [TokenAccount<AccountInfo>] {
        fatalError()
    }

    func getTokenAccountsByOwner(pubkey _: String, params _: OwnerInfoParams?,
                                 configs _: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>]
    {
        fatalError()
    }

    func getTokenLargestAccounts(pubkey _: String, commitment _: Commitment?) async throws -> [TokenAmount] {
        fatalError()
    }

    func getTokenSupply(pubkey _: String, commitment _: Commitment?) async throws -> TokenAmount {
        fatalError()
    }

    func getVersion() async throws -> Version {
        fatalError()
    }

    func getVoteAccounts(commitment _: Commitment?) async throws -> VoteAccounts {
        fatalError()
    }

    func minimumLedgerSlot() async throws -> UInt64 {
        fatalError()
    }

    func requestAirdrop(account _: String, lamports _: UInt64, commitment _: Commitment?) async throws -> String {
        fatalError()
    }

    func sendTransaction(transaction _: String, configs _: RequestConfiguration) async throws -> TransactionID {
        fatalError()
    }

    func simulateTransaction(transaction _: String, configs _: RequestConfiguration) async throws -> SimulationResult {
        fatalError()
    }

    func setLogFilter(filter _: String) async throws -> String? {
        fatalError()
    }

    func validatorExit() async throws -> Bool {
        fatalError()
    }

    func getMultipleAccounts<T>(pubkeys _: [String]) async throws -> [BufferInfo<T>] where T: BufferLayout {
        fatalError()
    }

    func getSignaturesForAddress(address _: String, configs _: RequestConfiguration?) async throws -> [SignatureInfo] {
        fatalError()
    }

    func getTransaction(signature _: String, commitment _: Commitment?) async throws -> TransactionInfo? {
        fatalError()
    }

    func batchRequest(with _: [JSONRPCRequestEncoder.RequestType]) async throws
    -> [AnyResponse<JSONRPCRequestEncoder.RequestType.Entity>] {
        fatalError()
    }

    func request<Entity>(method _: String, params _: [Encodable]) async throws -> Entity where Entity: Decodable {
        fatalError()
    }

    func getRecentBlockhash(commitment _: Commitment?) async throws -> String {
        fatalError()
    }

    func observeSignatureStatus(signature _: String, timeout _: Int, delay _: Int) -> AsyncStream<TransactionStatus> {
        fatalError()
    }

    func getMinimumBalanceForRentExemption(dataLength _: UInt64, commitment _: Commitment?) async throws -> UInt64 {
        2_039_280
    }

    func batchRequest<Entity>(method _: String, params _: [[Encodable]]) async throws -> [Entity?]
    where Entity: Decodable {
        fatalError()
    }

    func getRecentPerformanceSamples(
        limit _: [UInt]
    ) async throws -> [PerfomanceSamples] {
        fatalError("getRecentPerformanceSamples(limit:) has not been implemented")
    }

    func getSlot() async throws -> UInt64 {
        fatalError()
    }

    func getAddressLookupTable(accountKey _: SolanaSwift.PublicKey) async throws -> SolanaSwift
    .AddressLookupTableAccount? {
        fatalError()
    }

    func getMultipleAccounts<T>(
        pubkeys _: [String],
        commitment _: SolanaSwift.Commitment
    ) async throws -> [SolanaSwift.BufferInfo<T>?]
    where T: SolanaSwift.BufferLayout {
        fatalError()
    }
}
