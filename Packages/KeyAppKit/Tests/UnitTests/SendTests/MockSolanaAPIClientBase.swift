import Foundation
import SolanaSwift

class MockSolanaAPIClientBase: SolanaAPIClient {
    let endpoint: SolanaSwift.APIEndPoint = .init(address: "https://api.mainnet-beta.solana.com", network: .mainnetBeta)

    func request<Entity>(method _: String, params _: [Encodable]) async throws -> Entity where Entity: Decodable {
        fatalError()
    }

    func getRecentBlockhash(commitment _: SolanaSwift.Commitment?) async throws -> String {
        fatalError()
    }

    func getAccountInfo<T>(account _: String) async throws -> SolanaSwift.BufferInfo<T>?
        where T: SolanaSwift.BufferLayout
    {
        fatalError()
    }

    func getBalance(account _: String, commitment _: SolanaSwift.Commitment?) async throws -> UInt64 {
        fatalError()
    }

    func getBlockCommitment(block _: UInt64) async throws -> SolanaSwift.BlockCommitment {
        fatalError()
    }

    func getBlockTime(block _: UInt64) async throws -> Date {
        fatalError()
    }

    func getClusterNodes() async throws -> [SolanaSwift.ClusterNodes] {
        fatalError()
    }

    func getBlockHeight() async throws -> UInt64 {
        fatalError()
    }

    func getConfirmedBlocksWithLimit(startSlot _: UInt64, limit _: UInt64) async throws -> [UInt64] {
        fatalError()
    }

    func getConfirmedBlock(slot _: UInt64, encoding _: String) async throws -> SolanaSwift.ConfirmedBlock {
        fatalError()
    }

    func getConfirmedSignaturesForAddress(account _: String, startSlot _: UInt64,
                                          endSlot _: UInt64) async throws -> [String]
    {
        fatalError()
    }

    func getEpochInfo(commitment _: SolanaSwift.Commitment?) async throws -> SolanaSwift.EpochInfo {
        fatalError()
    }

    func getFees(commitment _: SolanaSwift.Commitment?) async throws -> SolanaSwift.Fee {
        fatalError()
    }

    func getSignatureStatuses(
        signatures _: [String],
        configs _: SolanaSwift.RequestConfiguration?
    ) async throws -> [SolanaSwift.SignatureStatus?] {
        fatalError()
    }

    func getSignatureStatus(signature _: String,
                            configs _: SolanaSwift.RequestConfiguration?) async throws -> SolanaSwift.SignatureStatus
    {
        fatalError()
    }

    func getTokenAccountBalance(pubkey _: String, commitment _: SolanaSwift.Commitment?) async throws -> SolanaSwift
        .TokenAccountBalance
    {
        fatalError()
    }

    func getTokenAccountsByDelegate<T: TokenAccountState>(
        pubkey _: String,
        mint _: String?,
        programId _: String?,
        configs _: RequestConfiguration?
    ) async throws -> [TokenAccount<T>] {
        fatalError()
    }

    func getTokenAccountsByOwner<T: TokenAccountState>(
        pubkey _: String,
        params _: OwnerInfoParams?,
        configs _: RequestConfiguration?,
        decodingTo _: T.Type
    ) async throws -> [TokenAccount<T>] {
        fatalError()
    }

    func getTokenLargestAccounts(pubkey _: String,
                                 commitment _: SolanaSwift.Commitment?) async throws -> [SolanaSwift.TokenAmount]
    {
        fatalError()
    }

    func getTokenSupply(pubkey _: String, commitment _: SolanaSwift.Commitment?) async throws -> SolanaSwift
        .TokenAmount
    {
        fatalError()
    }

    func getVersion() async throws -> SolanaSwift.Version {
        fatalError()
    }

    func getVoteAccounts(commitment _: SolanaSwift.Commitment?) async throws -> SolanaSwift.VoteAccounts {
        fatalError()
    }

    func minimumLedgerSlot() async throws -> UInt64 {
        fatalError()
    }

    func requestAirdrop(account _: String, lamports _: UInt64,
                        commitment _: SolanaSwift.Commitment?) async throws -> String
    {
        fatalError()
    }

    func sendTransaction(transaction _: String, configs _: SolanaSwift.RequestConfiguration) async throws -> SolanaSwift
        .TransactionID
    {
        fatalError()
    }

    func simulateTransaction(transaction _: String,
                             configs _: SolanaSwift.RequestConfiguration) async throws -> SolanaSwift.SimulationResult
    {
        fatalError()
    }

    func setLogFilter(filter _: String) async throws -> String? {
        fatalError()
    }

    func validatorExit() async throws -> Bool {
        fatalError()
    }

    func getMultipleAccounts<T>(pubkeys _: [String]) async throws -> [SolanaSwift.BufferInfo<T>]
        where T: SolanaSwift.BufferLayout
    {
        fatalError()
    }

    func getSignaturesForAddress(
        address _: String,
        configs _: SolanaSwift.RequestConfiguration?
    ) async throws -> [SolanaSwift.SignatureInfo] {
        fatalError()
    }

    func getTransaction(signature _: String, commitment _: SolanaSwift.Commitment?) async throws -> SolanaSwift
        .TransactionInfo?
    {
        fatalError()
    }

    func batchRequest(with _: [SolanaSwift.JSONRPCRequestEncoder.RequestType]) async throws
        -> [SolanaSwift.AnyResponse<SolanaSwift.JSONRPCRequestEncoder.RequestType.Entity>]
    {
        fatalError()
    }

    func batchRequest<Entity>(method _: String, params _: [[Encodable]]) async throws -> [Entity?]
        where Entity: Decodable
    {
        fatalError()
    }

    func getMinimumBalanceForRentExemption(dataLength _: UInt64,
                                           commitment _: SolanaSwift.Commitment?) async throws -> UInt64
    {
        fatalError()
    }

    func observeSignatureStatus(signature _: String, timeout _: Int,
                                delay _: Int) -> AsyncStream<SolanaSwift.PendingTransactionStatus>
    {
        fatalError()
    }

    func getRecentPerformanceSamples(limit _: [UInt]) async throws -> [SolanaSwift.PerfomanceSamples] {
        fatalError()
    }

    func getSlot() async throws -> UInt64 {
        fatalError()
    }

    func getAddressLookupTable(accountKey _: SolanaSwift.PublicKey) async throws -> SolanaSwift
        .AddressLookupTableAccount?
    {
        fatalError()
    }

    func getMultipleAccounts<T>(pubkeys _: [String],
                                commitment _: SolanaSwift.Commitment) async throws -> [SolanaSwift.BufferInfo<T>?]
        where T: SolanaSwift.BufferLayout
    {
        fatalError()
    }
}
