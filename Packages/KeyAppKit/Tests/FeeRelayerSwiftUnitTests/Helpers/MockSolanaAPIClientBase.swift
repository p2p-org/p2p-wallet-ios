import SolanaSwift
import Foundation

class MockSolanaAPIClientBase: SolanaAPIClient {
    let endpoint: SolanaSwift.APIEndPoint = .init(address: "https://api.mainnet-beta.solana.com", network: .mainnetBeta)
    
    func request<Entity>(method: String, params: [Encodable]) async throws -> Entity where Entity : Decodable {
        fatalError()
    }
    
    func getRecentBlockhash(commitment: SolanaSwift.Commitment?) async throws -> String {
        fatalError()
    }
    
    func getAccountInfo<T>(account: String) async throws -> SolanaSwift.BufferInfo<T>? where T : SolanaSwift.BufferLayout {
        fatalError()
    }
    
    func getBalance(account: String, commitment: SolanaSwift.Commitment?) async throws -> UInt64 {
        fatalError()
    }
    
    func getBlockCommitment(block: UInt64) async throws -> SolanaSwift.BlockCommitment {
        fatalError()
    }
    
    func getBlockTime(block: UInt64) async throws -> Date {
        fatalError()
    }
    
    func getClusterNodes() async throws -> [SolanaSwift.ClusterNodes] {
        fatalError()
    }
    
    func getBlockHeight() async throws -> UInt64 {
        fatalError()
    }
    
    func getConfirmedBlocksWithLimit(startSlot: UInt64, limit: UInt64) async throws -> [UInt64] {
        fatalError()
    }
    
    func getConfirmedBlock(slot: UInt64, encoding: String) async throws -> SolanaSwift.ConfirmedBlock {
        fatalError()
    }
    
    func getConfirmedSignaturesForAddress(account: String, startSlot: UInt64, endSlot: UInt64) async throws -> [String] {
        fatalError()
    }
    
    func getEpochInfo(commitment: SolanaSwift.Commitment?) async throws -> SolanaSwift.EpochInfo {
        fatalError()
    }
    
    func getFees(commitment: SolanaSwift.Commitment?) async throws -> SolanaSwift.Fee {
        fatalError()
    }
    
    func getSignatureStatuses(signatures: [String], configs: SolanaSwift.RequestConfiguration?) async throws -> [SolanaSwift.SignatureStatus?] {
        fatalError()
    }
    
    func getSignatureStatus(signature: String, configs: SolanaSwift.RequestConfiguration?) async throws -> SolanaSwift.SignatureStatus {
        fatalError()
    }
    
    func getTokenAccountBalance(pubkey: String, commitment: SolanaSwift.Commitment?) async throws -> SolanaSwift.TokenAccountBalance {
        fatalError()
    }
    
    func getTokenAccountsByDelegate(pubkey: String, mint: String?, programId: String?, configs: SolanaSwift.RequestConfiguration?) async throws -> [SolanaSwift.TokenAccount<SolanaSwift.AccountInfo>] {
        fatalError()
    }
    
    func getTokenAccountsByOwner(pubkey: String, params: SolanaSwift.OwnerInfoParams?, configs: SolanaSwift.RequestConfiguration?) async throws -> [SolanaSwift.TokenAccount<SolanaSwift.AccountInfo>] {
        fatalError()
    }
    
    func getTokenLargestAccounts(pubkey: String, commitment: SolanaSwift.Commitment?) async throws -> [SolanaSwift.TokenAmount] {
        fatalError()
    }
    
    func getTokenSupply(pubkey: String, commitment: SolanaSwift.Commitment?) async throws -> SolanaSwift.TokenAmount {
        fatalError()
    }
    
    func getVersion() async throws -> SolanaSwift.Version {
        fatalError()
    }
    
    func getVoteAccounts(commitment: SolanaSwift.Commitment?) async throws -> SolanaSwift.VoteAccounts {
        fatalError()
    }
    
    func minimumLedgerSlot() async throws -> UInt64 {
        fatalError()
    }
    
    func requestAirdrop(account: String, lamports: UInt64, commitment: SolanaSwift.Commitment?) async throws -> String {
        fatalError()
    }
    
    func sendTransaction(transaction: String, configs: SolanaSwift.RequestConfiguration) async throws -> SolanaSwift.TransactionID {
        fatalError()
    }
    
    func simulateTransaction(transaction: String, configs: SolanaSwift.RequestConfiguration) async throws -> SolanaSwift.SimulationResult {
        fatalError()
    }
    
    func setLogFilter(filter: String) async throws -> String? {
        fatalError()
    }
    
    func validatorExit() async throws -> Bool {
        fatalError()
    }
    
    func getMultipleAccounts<T>(pubkeys: [String]) async throws -> [SolanaSwift.BufferInfo<T>] where T : SolanaSwift.BufferLayout {
        fatalError()
    }
    
    func getSignaturesForAddress(address: String, configs: SolanaSwift.RequestConfiguration?) async throws -> [SolanaSwift.SignatureInfo] {
        fatalError()
    }
    
    func getTransaction(signature: String, commitment: SolanaSwift.Commitment?) async throws -> SolanaSwift.TransactionInfo? {
        fatalError()
    }
    
    func batchRequest(with requests: [SolanaSwift.JSONRPCRequestEncoder.RequestType]) async throws -> [SolanaSwift.AnyResponse<SolanaSwift.JSONRPCRequestEncoder.RequestType.Entity>] {
        fatalError()
    }
    
    func batchRequest<Entity>(method: String, params: [[Encodable]]) async throws -> [Entity?] where Entity : Decodable {
        fatalError()
    }
    
    func getMinimumBalanceForRentExemption(dataLength: UInt64, commitment: SolanaSwift.Commitment?) async throws -> UInt64 {
        fatalError()
    }
    
    func observeSignatureStatus(signature: String, timeout: Int, delay: Int) -> AsyncStream<SolanaSwift.TransactionStatus> {
        fatalError()
    }
    
    func getRecentPerformanceSamples(limit: [UInt]) async throws -> [SolanaSwift.PerfomanceSamples] {
        fatalError()
    }
    
    func getSlot() async throws -> UInt64 {
        fatalError()
    }
    
    func getAddressLookupTable(accountKey: SolanaSwift.PublicKey) async throws -> SolanaSwift.AddressLookupTableAccount? {
        fatalError()
    }
}
