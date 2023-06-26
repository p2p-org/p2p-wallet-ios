import Foundation
import XCTest
import SolanaSwift
@testable import OrcaSwapSwift

final class SwapIntegrationTests: XCTestCase {
    // MARK: - Properties
    var orcaSwap: OrcaSwap!
    
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
        let test = try await doTest(testJSONFile: "transitive-swap-tests", testName: "solToNonCreatedSpl", isSimulation: true)
        
        try closeAssociatedToken(mint: test.toMint)
    }

    func testTransitiveSwapSPLToSOL() async throws {
        try await doTest(testJSONFile: "transitive-swap-tests", testName: "splToSol", isSimulation: true)
    }
    
    func testTransitiveSwapSPLToCreatedSPL() async throws {
        try await doTest(testJSONFile: "transitive-swap-tests", testName: "splToCreatedSpl", isSimulation: true)
    }
    
    func testTransitiveSwapSPLToNonCreatedSPL() async throws {
        let test = try await doTest(testJSONFile: "transitive-swap-tests", testName: "splToNonCreatedSpl", isSimulation: true)
        
        try closeAssociatedToken(mint: test.toMint)
    }
    
    
    // MARK: - Helpers
    @discardableResult
    func doTest(testJSONFile: String, testName: String, isSimulation: Bool) async throws -> SwapTest {
        let test = try getDataFromJSONTestResourceFile(fileName: testJSONFile, decodedTo: [String: SwapTest].self)[testName]!
        
        let network = Network.mainnetBeta
        let orcaSwapNetwork = network == .mainnetBeta ? "mainnet": network.cluster
        
        let solanaAPIClient = JSONRPCAPIClient(endpoint: .init(address: test.endpoint, network: network, additionalQuery: test.endpointAdditionalQuery))
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
    
    func closeAssociatedToken(mint: String) throws {
        let associatedTokenAddress = try PublicKey.associatedTokenAddress(
            walletAddress: orcaSwap.accountStorage.account!.publicKey,
            tokenMintAddress: try PublicKey(string: mint)
        )
        
//        let _ = try orcaSwap.solanaClient.closeTokenAccount(
//            tokenPubkey: associatedTokenAddress.base58EncodedString
//        )
//            .retry { errors in
//                errors.enumerated().flatMap{ (index, error) -> Observable<Int64> in
//                    let error = error as! SolanaError
//                    switch error {
//                    case .invalidResponse(let error) where error.data?.logs?.contains("Program log: Error: InvalidAccountData") == true:
//                        return .timer(.seconds(1), scheduler: MainScheduler.instance)
//                    default:
//                        break
//                    }
//                    return .error(error)
//                }
//            }
//            .timeout(.seconds(60), scheduler: MainScheduler.instance)
//            .toBlocking().first()
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
    
    init(account: KeyPair) {
        self.account = account
    }
    
    func save(_ account: KeyPair) throws {
        // do nothing
    }
}
