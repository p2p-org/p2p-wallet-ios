import Foundation
import XCTest
@testable import SolanaSwift
@testable import OrcaSwapSwift

final class SwapTests: XCTestCase {
    // MARK: - Properties
    fileprivate var orcaSwap: OrcaSwap!
    
    // MARK: - Setup
    override func setUp() async throws {
//        poolsRepository = getMockConfigs(network: "mainnet").pools
    }
    
    override func tearDown() async throws {
        orcaSwap = nil
    }
    
    // MARK: - Direct swap
    func testDirectSwapSOLToCreatedSPL() async throws {
        try await doTest(testJSONFile: "direct-swap-tests", testName: "solToCreatedSpl", isSimulation: true)
    }
    
    func testDirectSwapSOLToNonCreatedSPL() async throws {
        try await doTest(testJSONFile: "direct-swap-tests", testName: "solToNonCreatedSpl", isSimulation: true)
    }
    
    func testDirectSwapSPLToSOL() async throws {
        try await doTest(testJSONFile: "direct-swap-tests", testName: "splToSol", isSimulation: true)
    }
    
    func testDirectSwapSPLToCreatedSPL() async throws {
        try await doTest(testJSONFile: "direct-swap-tests", testName: "splToCreatedSpl", isSimulation: true)
    }
    
    func testDirectSwapSPLToNonCreatedSPL() async throws {
        try await doTest(testJSONFile: "direct-swap-tests", testName: "splToNonCreatedSpl", isSimulation: true)
    }
    
    // MARK: - Transitive swap
    func testTransitiveSwapSOLToCreatedSPL() async throws {
        try await doTest(testJSONFile: "transitive-swap-tests", testName: "solToCreatedSpl", isSimulation: true)
    }
    
    func testTransitiveSwapSOLToNonCreatedSPL() async throws {
        try await doTest(testJSONFile: "transitive-swap-tests", testName: "solToNonCreatedSpl", isSimulation: true)
    }

    func testTransitiveSwapSPLToSOL() async throws {
        try await doTest(testJSONFile: "transitive-swap-tests", testName: "splToSol", isSimulation: true)
    }
    
    func testTransitiveSwapSPLToCreatedSPL() async throws {
        try await doTest(testJSONFile: "transitive-swap-tests", testName: "splToCreatedSpl", isSimulation: true)
    }
    
    func testTransitiveSwapSPLToNonCreatedSPL() async throws {
        try await doTest(testJSONFile: "transitive-swap-tests", testName: "splToNonCreatedSpl", isSimulation: true)
    }
    
    // MARK: - Helpers
    @discardableResult
    func doTest(testJSONFile: String, testName: String, isSimulation: Bool) async throws -> SwapTest {
        let test = try getDataFromJSONTestResourceFile(fileName: testJSONFile, decodedTo: [String: SwapTest].self)[testName]!
        
        let network = Network.mainnetBeta
        let solanaAPIClient = MockSolanaAPIClient2(endpoint: .init(address: test.endpoint, network: network, additionalQuery: test.endpointAdditionalQuery), networkManager: URLSession.shared)
        let blockchainClient = BlockchainClient(apiClient: solanaAPIClient)
        orcaSwap = OrcaSwap(
            apiClient: APIClient(configsProvider: MockConfigsProvider()),
            solanaClient: solanaAPIClient,
            blockchainClient: blockchainClient,
            accountStorage: MockAccountStorage(
                account: try await KeyPair(
                    phrase: test.seedPhrase.components(separatedBy: " "),
                    network: network
                )
            )
        )
        try await orcaSwap.load()
        
        let _ = try await fillPoolsBalancesAndSwap(
            fromWalletPubkey: test.sourceAddress,
            toWalletPubkey: test.destinationAddress,
            bestPoolsPair: test.poolsPair,
            amount: test.inputAmount,
            slippage: test.slippage,
            isSimulation: isSimulation
        )
        
        return test
    }
    
    // MARK: - Helper
    func fillPoolsBalancesAndSwap(
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: [RawPool],
        amount: Double,
        slippage: Double,
        isSimulation: Bool
    ) async throws -> SwapResponse {
        let poolsFromAPI = try await orcaSwap.apiClient.getPools()
        var pools = [OrcaSwapSwift.Pool]()
        for rawPool in bestPoolsPair {
            var pool = poolsFromAPI[rawPool.name]!
            if rawPool.reversed {
                pool = pool.reversed
            }
            pool = try await pool.filledWithUpdatedBalances(apiClient: orcaSwap.solanaClient)
            pools.append(pool)
        }
        
        return try await orcaSwap.swap(
            fromWalletPubkey: fromWalletPubkey,
            toWalletPubkey: toWalletPubkey,
            bestPoolsPair: pools,
            amount: amount,
            slippage: 0.5,
            isSimulation: isSimulation
        )
    }
}

private extension OrcaSwapSwift.Pool {
    func filledWithUpdatedBalances(apiClient: SolanaAPIClient) async throws -> OrcaSwapSwift.Pool {
        let (tokenABalance, tokenBBalance) = try await (
            apiClient.getTokenAccountBalance(pubkey: tokenAccountA, commitment: nil),
            apiClient.getTokenAccountBalance(pubkey: tokenAccountB, commitment: nil)
        )
        var pool = self
        pool.tokenABalance = tokenABalance
        pool.tokenBBalance = tokenBBalance
        return pool
    }
}

private struct MockAccountStorage: SolanaAccountStorage {
    let account: KeyPair?
    init(account: KeyPair?) {
        self.account = account
    }
    
    func save(_ account: KeyPair) throws {
        // do nothing
    }
}

public class MockSolanaAPIClient2: BaseMockSolanaAPIClient {
    
    public override func getTokenAccountBalance(pubkey: String, commitment: Commitment?) async throws -> TokenAccountBalance {
        switch pubkey {
        case "FdiTt7XQ94fGkgorywN1GuXqQzmURHCDgYtUutWRcy4q":
            return TokenAccountBalance(amount: 389.627856679, decimals: 9)
        case "7VcwKUtdKnvcgNhZt5BQHsbPrXLxhdVomsgrr7k2N5P5":
            return TokenAccountBalance(amount: 27053.369728, decimals: 6)
        case "DTb8NKsfhEJGY1TrA7RXN6MBiTrjnkdMAfjPEjtmTT3M":
            return TokenAccountBalance(amount: 27053.369728, decimals: 6)
        case "E8erPjPEorykpPjFV9yUYMYigEWKQUxuGfL2rJKLJ3KU":
            return TokenAccountBalance(amount: 27053.369728, decimals: 6)
        default:
            return TokenAccountBalance(amount: 27053.369728, decimals: 6)
        }
    }
    
    public override func getMinimumBalanceForRentExemption(dataLength: UInt64, commitment: Commitment? = "recent") async throws -> UInt64 {
        2039280
    }
    
    public func getMinimumBalanceForRentExemption(span: UInt64) async throws -> UInt64 {
        2039280
    }
    
    public override func getFees(commitment: Commitment? = nil) async throws -> Fee {
        .init(feeCalculator: .init(lamportsPerSignature: 5000), feeRateGovernor: nil, blockhash: "ADZgUVaAfUx5ehFXivdaUSHucpNdk4VqGSdN4TjttWgr", lastValidSlot: 133257026)
    }
    
    public override func getRecentBlockhash(commitment: Commitment? = nil) async throws -> String {
        "NS37crgkUQQwwFjdEdWNQFCyatLGN68F55FG2Hv4FFS"
    }
    
    public override func sendTransaction(transaction: String, configs: RequestConfiguration = RequestConfiguration(encoding: "base64")!) async throws -> TransactionID {
        return ""
    }
}

public class MockNetworkManager: NetworkManager {
    public func requestData(request: URLRequest) async throws -> Data {
        // Simulate transaction json
        return "{\"jsonrpc\":\"2.0\",\"result\":{\"context\":{\"slot\":133610519},\"value\":{\"accounts\":null,\"err\":null,\"logs\":[\"Program 11111111111111111111111111111111 invoke [1]\",\"Program 11111111111111111111111111111111 success\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [1]\",\"Program log: Instruction: InitializeAccount\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 3392 of 200000 compute units\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success\",\"Program DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1 invoke [1]\",\"Program log: Instruction: Swap\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [2]\",\"Program log: Instruction: Transfer\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 2755 of 182466 compute units\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [2]\",\"Program log: Instruction: Transfer\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 2643 of 176749 compute units\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success\",\"Program DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1 consumed 26775 of 200000 compute units\",\"Program DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1 success\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [1]\",\"Program log: Instruction: CloseAccount\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 1713 of 200000 compute units\",\"Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success\"],\"unitsConsumed\":31880}},\"id\":\"345443BB-2FC6-4935-8F52-7D031BAE345B\"}\n".data(using: .utf8) ?? Data()
    }
}

public class BaseMockSolanaAPIClient: JSONRPCAPIClient {
    public override init(endpoint: APIEndPoint, networkManager: NetworkManager) {
        super.init(endpoint: endpoint, networkManager: MockNetworkManager())
    }
}
