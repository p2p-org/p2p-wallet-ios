import Foundation
@testable import SolanaSwift

class MockSolanaAPIClient: SolanaAPIClient {
    var endpoint: APIEndPoint {
        APIEndPoint.defaultEndpoints.first!
    }
    
    func getAccountInfo<T>(account: String) async throws -> BufferInfo<T>? where T : BufferLayout {
        switch account {
        case "BjUEdE292SLEq9mMeKtY3GXL6wirn7DqJPhrukCqAUua":
            return nil
        case "8Vu3KXjZJPUdUf7cRWR9ukXuahoV9vNU5ExEo52SNH4G":
            var binaryReader = BinaryReader(bytes: Data(base64Encoded: "BoMQhhqYMn0FUFdNhEGKpuEMM1Ldqn/X9YFSzO6yOIdi/XalJxOwfrmp1jI9t6I30VBlnsq7A+waTZA0Mr2M+3GeHQcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")!.bytes)
            return .init(
                lamports: 2039280,
                owner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                data: try! AccountInfo(from: &binaryReader) as! T,
                executable: false,
                rentEpoch: 316
            )
        case "EFs4FuHmb3bbC4BUD4tu188x4k5UMmxPbm6PZQjDnxL6":
            var binaryReader = BinaryReader(bytes: Data(base64Encoded: "BpuIV/6rgYT7aH9jRhjANdrEOdwa6ztVmKDwAAAAAAFi/XalJxOwfrmp1jI9t6I30VBlnsq7A+waTZA0Mr2M+8X0TbsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAADwHR8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")!.bytes)
            return .init(
                lamports: 3144487605,
                owner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                data: try! AccountInfo(from: &binaryReader) as! T,
                executable: false,
                rentEpoch: 316
            )
        case "HVc47am8HPYgvkkCiFJzV6Q8qsJJKJUYT6o7ucd6ZYXY":
            return nil
        case "FdiTt7XQ94fGkgorywN1GuXqQzmURHCDgYtUutWRcy4q":
            var binaryReader = BinaryReader(bytes: Data(base64Encoded: "BpuIV/6rgYT7aH9jRhjANdrEOdwa6ztVmKDwAAAAAAGVnOqUkPJVr6muuizyY38m7w+KGKPwmhy/esO7Llb6UB/ruyd7AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAADwHR8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")!.bytes)
            return .init(
                lamports: 562102267325,
                owner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                data: try! AccountInfo(from: &binaryReader) as! T,
                executable: false,
                rentEpoch: 316
            )
        case "ErcxwkPgLdyoVL6j2SsekZ5iysPZEDRGfAggh282kQb8":
            var binaryReader = BinaryReader(bytes: Data(base64Encoded: "DlY5XjyGAUOALpuUoCzG0E91/scqP7txUmg1XgzXzYlZ9QCnv3uHbULVucoY03CjVfA+0o2LoUEOuFZWBIqlfMNn0YsuAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")!.bytes)
            return .init(
                lamports: 2039280,
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
    
    func getBalance(account: String, commitment: Commitment?) async throws -> UInt64 {
        fatalError()
    }
    
    func getBlockCommitment(block: UInt64) async throws -> BlockCommitment {
        fatalError()
    }
    
    func getBlockTime(block: UInt64) async throws -> Date {
        fatalError()
    }
    
    func getClusterNodes() async throws -> [ClusterNodes] {
        fatalError()
    }
    
    func getBlockHeight() async throws -> UInt64 {
        fatalError()
    }
    
    func getConfirmedBlocksWithLimit(startSlot: UInt64, limit: UInt64) async throws -> [UInt64] {
        fatalError()
    }
    
    func getConfirmedBlock(slot: UInt64, encoding: String) async throws -> ConfirmedBlock {
        fatalError()
    }
    
    func getConfirmedSignaturesForAddress(account: String, startSlot: UInt64, endSlot: UInt64) async throws -> [String] {
        fatalError()
    }
    
    func getEpochInfo(commitment: Commitment?) async throws -> EpochInfo {
        fatalError()
    }
    
    func getFees(commitment: Commitment?) async throws -> Fee {
        .init(feeCalculator: .init(lamportsPerSignature: 5000), feeRateGovernor: nil, blockhash: "GwXLB5biQoCEGPB1auCSoob87GBkiN9bqF8R78nsdSFp", lastValidSlot: 136873719)
    }
    
    func getSignatureStatuses(signatures: [String], configs: RequestConfiguration?) async throws -> [SignatureStatus?] {
        fatalError()
    }
    
    func getSignatureStatus(signature: String, configs: RequestConfiguration?) async throws -> SignatureStatus {
        fatalError()
    }
    
    func getTokenAccountBalance(pubkey: String, commitment: Commitment?) async throws -> TokenAccountBalance {
        fatalError()
    }
    
    func getTokenAccountsByDelegate(pubkey: String, mint: String?, programId: String?, configs: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>] {
        fatalError()
    }
    
    func getTokenAccountsByOwner(pubkey: String, params: OwnerInfoParams?, configs: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>] {
        fatalError()
    }
    
    func getTokenLargestAccounts(pubkey: String, commitment: Commitment?) async throws -> [TokenAmount] {
        fatalError()
    }
    
    func getTokenSupply(pubkey: String, commitment: Commitment?) async throws -> TokenAmount {
        fatalError()
    }
    
    func getVersion() async throws -> Version {
        fatalError()
    }
    
    func getVoteAccounts(commitment: Commitment?) async throws -> VoteAccounts {
        fatalError()
    }
    
    func minimumLedgerSlot() async throws -> UInt64 {
        fatalError()
    }
    
    func requestAirdrop(account: String, lamports: UInt64, commitment: Commitment?) async throws -> String {
        fatalError()
    }
    
    func sendTransaction(transaction: String, configs: RequestConfiguration) async throws -> TransactionID {
        fatalError()
    }
    
    func simulateTransaction(transaction: String, configs: RequestConfiguration) async throws -> SimulationResult {
        fatalError()
    }
    
    func setLogFilter(filter: String) async throws -> String? {
        fatalError()
    }
    
    func validatorExit() async throws -> Bool {
        fatalError()
    }
    
    func getMultipleAccounts<T>(pubkeys: [String]) async throws -> [BufferInfo<T>] where T : BufferLayout {
        fatalError()
    }
    
    func getSignaturesForAddress(address: String, configs: RequestConfiguration?) async throws -> [SignatureInfo] {
        fatalError()
    }
    
    func getTransaction(signature: String, commitment: Commitment?) async throws -> TransactionInfo? {
        fatalError()
    }
    
    func batchRequest(with requests: [JSONRPCRequestEncoder.RequestType]) async throws -> [AnyResponse<JSONRPCRequestEncoder.RequestType.Entity>] {
        fatalError()
    }
    
    func request<Entity>(method: String, params: [Encodable]) async throws -> Entity where Entity : Decodable {
        fatalError()
    }
    
    func getRecentBlockhash(commitment: Commitment?) async throws -> String {
        fatalError()
    }
    
    func observeSignatureStatus(signature: String, timeout: Int, delay: Int) -> AsyncStream<TransactionStatus> {
        fatalError()
    }
    
    func getMinimumBalanceForRentExemption(dataLength: UInt64, commitment: Commitment?) async throws -> UInt64 {
        2039280
    }
    
    func batchRequest<Entity>(method: String, params: [[Encodable]]) async throws -> [Entity?] where Entity : Decodable {
        fatalError()
    }
    
    func getRecentPerformanceSamples(
        limit: [UInt]
    ) async throws -> [PerfomanceSamples] {
        fatalError("getRecentPerformanceSamples(limit:) has not been implemented")
    }
}
