import XCTest
@testable import Send
import SolanaSwift

class SendViaLinkDataServiceImplTests: XCTestCase {
    
    var service: SendViaLinkDataServiceImpl!
    let validSeed = "e0EKk5xKdsO4BOh~"
    let host = "test.example.com"
    let salt = "testSalt"
    let passphrase = "testPassphrase"
    
    private var solanaAPIClient: MockSolanaAPIClient!
    
    override func setUp() {
        super.setUp()
        
        solanaAPIClient = MockSolanaAPIClient()
        
        // Initialize the service with your desired parameters
        service = SendViaLinkDataServiceImpl(
            salt: salt,
            passphrase: passphrase,
            network: .mainnetBeta,
            derivablePath: .default,
            host: host,
            solanaAPIClient: solanaAPIClient
        )
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Seed validation

    func testCheckSeedValidation_ShouldReturnSuccess() {
        XCTAssertNoThrow(try service.checkSeedValidation(seed: validSeed))
    }
    
    func testCheckSeedValidation_ShouldReturnFailure() {
        XCTAssertThrowsError(try service.checkSeedValidation(seed: invalidSeedWithSmallerLength)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        
        XCTAssertThrowsError(try service.checkSeedValidation(seed: invalidSeedWithGreaterLength)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        
        XCTAssertThrowsError(try service.checkSeedValidation(seed: invalidSeedWithInvalidCharacter)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
    }
    
    // MARK: - Create URL

    func testCreateURL_ShouldNotCrash() throws {
        _ = service.createURL()
    }
    
    // MARK: - Restore URL

    func testRestoreURL_WithValidSeed_ShouldReturnSuccess() throws {
        let expectedURLString = "https://test.example.com/\(validSeed)"
        let url = try service.restoreURL(givenSeed: validSeed)
        
        XCTAssertEqual(url.absoluteString, expectedURLString)
    }
    
    func testRestoreURL_WithInvalidSeed_ShouldReturnFailure() throws {
        XCTAssertThrowsError(try service.restoreURL(givenSeed: invalidSeedWithSmallerLength)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        XCTAssertThrowsError(try service.restoreURL(givenSeed: invalidSeedWithGreaterLength)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        XCTAssertThrowsError(try service.restoreURL(givenSeed: invalidSeedWithInvalidCharacter)) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
    }
    
    // MARK: - GetSeedFromURL
    
    func testGetSeedFromURL_WithValidURL_ShouldReturnSuccess() throws {
        let url = URL(string: "https://test.example.com/\(validSeed)")!
        let resultSeed = try service.getSeedFromURL(url)
        
        XCTAssertEqual(resultSeed, validSeed)
    }
    
    func testGetSeedFromURL_WithInvalidURL_ShouldReturnFailure() throws {
        XCTAssertThrowsError(try service.getSeedFromURL(inValidHostWithSeed(validSeed))) { error in
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidURL)
        }
        XCTAssertThrowsError(try service.getSeedFromURL(validHostWithSeed(invalidSeedWithSmallerLength))) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        XCTAssertThrowsError(try service.getSeedFromURL(validHostWithSeed(invalidSeedWithGreaterLength))) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
        XCTAssertThrowsError(try service.getSeedFromURL(validHostWithSeed(invalidSeedWithInvalidCharacter))) {
            XCTAssertEqual($0 as! SendViaLinkDataServiceError, .invalidSeed)
        }
    }
    
    // MARK: - Generate KeyPair

    func testGenerateKeyPair_WithValidURL_ShouldReturnSuccess() async throws {
        let keyPair = try await service.generateKeyPair(url: validHostWithSeed(validSeed))
        let secretKey = "IkJEeUOufBVp14mjwuHiIb6GkAqPL+w4S95Qw/i6WLFmGS9BVzhQVAQ9Kta7r9fHy0JHO4W7K7q9G88xBV6OnA=="
        let publicKey = "7sYroAgRW6TmmXTHH7vwG2yZFUVhN7u8j8iArywLUcgs"
        
        // Ensure the key pair has been generated correctly
        XCTAssertEqual(keyPair.secretKey.base64EncodedString(), secretKey)
        XCTAssertEqual(keyPair.publicKey.base58EncodedString, publicKey)
    }
    
    func testGenerateKeyPair_WithInValidURL_ShouldReturnFailure() async throws {
        do {
            _ = try await service.generateKeyPair(url: inValidHostWithSeed(validSeed))
        } catch {
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidURL)
        }
        
        do {
            _ = try await service.generateKeyPair(url: validHostWithSeed(invalidSeedWithSmallerLength))
        } catch {
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidSeed)
        }
        
        do {
            _ = try await service.generateKeyPair(url: validHostWithSeed(invalidSeedWithGreaterLength))
        } catch {
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidSeed)
        }
        
        do {
            _ = try await service.generateKeyPair(url: validHostWithSeed(invalidSeedWithInvalidCharacter))
        } catch {
            XCTAssertEqual(error as! SendViaLinkDataServiceError, .invalidSeed)
        }
    }
    
    // MARK: - Get claimable native sol

    func testGetClaimableSOLTokenInfo_WithValidLastTransaction_ShouldReturnSuccess() async throws {
        solanaAPIClient.getSignaturesForAddressResponse = validGetSignaturesForAddressResponse
        solanaAPIClient.getTransactionResponse = validGetSendSOLTransactionResponse
        
        let claimableTokenInfo = try await service.getClaimableTokenInfo(url: validHostWithSeed(validSeed))
        XCTAssertEqual(claimableTokenInfo.lamports, 1000000)
        XCTAssertEqual(claimableTokenInfo.mintAddress, Token.nativeSolana.address)
        XCTAssertEqual(claimableTokenInfo.decimals, 9)
        XCTAssertEqual(claimableTokenInfo.account, "2b7iQq3PbWwWTotRSDFNXT9DauU418aCHK4jcAzETUem")
    }
    
    func testGetClaimableSOLTokenInfo_WithInValidLastTransaction_ButValidAccountBalance_ShouldReturnSuccess() async throws {
        solanaAPIClient.getSignaturesForAddressResponse = "" // invalid
        solanaAPIClient.getTransactionResponse = "" // invalid
        solanaAPIClient.getBalanceResponse = validGetBalanceResponse(balance: 1000000) // invalid
        
        let claimableTokenInfo = try await service.getClaimableTokenInfo(url: validHostWithSeed(validSeed))
        XCTAssertEqual(claimableTokenInfo.lamports, 1000000)
        XCTAssertEqual(claimableTokenInfo.mintAddress, Token.nativeSolana.address)
        XCTAssertEqual(claimableTokenInfo.decimals, 9)
        XCTAssertEqual(claimableTokenInfo.account, "7sYroAgRW6TmmXTHH7vwG2yZFUVhN7u8j8iArywLUcgs")
    }
    
    // MARK: - Get claimable spl token

    func testGetClaimableSPLTokenInfo_WithValidLastTransaction_ShouldReturnSuccess() async throws {
        solanaAPIClient.getSignaturesForAddressResponse = validGetSignaturesForAddressResponse
        solanaAPIClient.getTransactionResponse = validGetSendSPLTransactionResponse
        
        let claimableTokenInfo = try await service.getClaimableTokenInfo(url: validHostWithSeed(validSeed))
        XCTAssertEqual(claimableTokenInfo.lamports, 1000)
        XCTAssertEqual(claimableTokenInfo.mintAddress, "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
        XCTAssertEqual(claimableTokenInfo.decimals, 6)
        XCTAssertEqual(claimableTokenInfo.account, "H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh")
    }
    
    func testGetClaimableSPLTokenInfo_WithInValidLastTransaction_ButValidAccountBalance_ShouldReturnSuccess() async throws {
        solanaAPIClient.getSignaturesForAddressResponse = "" // invalid
        solanaAPIClient.getTransactionResponse = "" // invalid
        solanaAPIClient.getBalanceResponse = "" // invalid
        solanaAPIClient.getTokensAccountByOwnerResponse = validGetTokenAccountsByOwnerResponse
        solanaAPIClient.getTokenAccountBalanceResponse = validGetTokenAccountBalanceResponse
        
        let claimableTokenInfo = try await service.getClaimableTokenInfo(url: validHostWithSeed(validSeed))
        XCTAssertEqual(claimableTokenInfo.lamports, 1000)
        XCTAssertEqual(claimableTokenInfo.mintAddress, "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
        XCTAssertEqual(claimableTokenInfo.decimals, 6)
        XCTAssertEqual(claimableTokenInfo.account, "H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh")
    }
    
    
    // MARK: - Helper
    
    func validHostWithSeed(_ seed: String) -> URL {
        URL(string: "https://test.example.com/\(seed)")!
    }
    
    func inValidHostWithSeed(_ seed: String) -> URL {
        URL(string: "https://test.example-something.com/\(seed)")!
    }
    
    var invalidSeedWithSmallerLength: String {
        "12343232"
    }
    
    var invalidSeedWithGreaterLength: String {
        "123456789123443343"
    }
    
    var invalidSeedWithInvalidCharacter: String {
        "Abcde1234!$()*+,-.#"
    }
}

// MARK: - MockSolanaAPIClient

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    var getSignaturesForAddressResponse: String!
    var getTransactionResponse: String!
    var getBalanceResponse: String!
    var getTokensAccountByOwnerResponse: String!
    var getTokenAccountBalanceResponse: String!
    
    override func getBalance(account: String, commitment: Commitment?) async throws -> UInt64 {
        try decode(Rpc<UInt64>.self, from: getBalanceResponse).value
    }
    
    override func getSignaturesForAddress(address: String, configs: RequestConfiguration?) async throws -> [SignatureInfo] {
        try decode([SignatureInfo].self, from: getSignaturesForAddressResponse)
    }
    
    override func getTransaction(signature: String, commitment: Commitment?) async throws -> TransactionInfo? {
        try decode(TransactionInfo.self, from: getTransactionResponse)
    }
    
    override func getTokenAccountsByOwner(pubkey: String, params: OwnerInfoParams?, configs: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>] {
        try decode(Rpc<[TokenAccount<AccountInfo>]>.self, from: getTokensAccountByOwnerResponse).value
    }
    
    override func getTokenAccountBalance(pubkey: String, commitment: Commitment?) async throws -> TokenAccountBalance {
        try decode(Rpc<TokenAccountBalance>.self, from: getTokenAccountBalanceResponse).value
    }
    
    private func decode<T: Decodable>(_ elementType: T.Type, from string: String) throws -> T {
        try JSONDecoder().decode(AnyResponse<T>.self, from: string.data(using: .utf8)!).result!
    }
}

private func validGetBalanceResponse(balance: UInt64) -> String {
    #"{"jsonrpc":"2.0","result":{"context":{"apiVersion":"1.14.16","slot":185436657},"value":\#(balance)},"id":1}"#
}

private var validGetSignaturesForAddressResponse: String {
    #"{"jsonrpc":"2.0","result":[{"blockTime":1679899845,"confirmationStatus":"finalized","err":null,"memo":"[8] transfer","signature":"2S2rTZjaqzxYRw9mnqzwtyqitKtSsnE8GVqLn1KrD5R2YpXZnU4GdjppsgfSAbrzJfaqadfi8CtrqEBy588WVQ3E","slot":184930610}],"id":1}"#
}

private var validGetSendSPLTransactionResponse: String {
    #"{"jsonrpc":"2.0","result":{"blockTime":1679899845,"meta":{"err":null,"fee":10000,"innerInstructions":[{"index":0,"instructions":[{"parsed":{"info":{"extensionTypes":["immutableOwner"],"mint":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"},"type":"getAccountDataSize"},"program":"spl-token","programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"},{"parsed":{"info":{"lamports":2039280,"newAccount":"H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh","owner":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","source":"FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT","space":165},"type":"createAccount"},"program":"system","programId":"11111111111111111111111111111111"},{"parsed":{"info":{"account":"H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh"},"type":"initializeImmutableOwner"},"program":"spl-token","programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"},{"parsed":{"info":{"account":"H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh","mint":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","owner":"3i476kTBBTy7pBGx4CXwJpJ6phuwLQgcwLTdHhU3c7ui"},"type":"initializeAccount3"},"program":"spl-token","programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"}]}],"logMessages":["Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL invoke [1]","Program log: Create","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [2]","Program log: Instruction: GetAccountDataSize","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 1622 of 594408 compute units","Program return: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA pQAAAAAAAAA=","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success","Program 11111111111111111111111111111111 invoke [2]","Program 11111111111111111111111111111111 success","Program log: Initialize the associated token account","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [2]","Program log: Instruction: InitializeImmutableOwner","Program log: Please upgrade to SPL Token 2022 for immutable owner support","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 1405 of 587918 compute units","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [2]","Program log: Instruction: InitializeAccount3","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 4241 of 584034 compute units","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success","Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL consumed 20545 of 600000 compute units","Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL success","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [1]","Program log: Instruction: TransferChecked","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 6200 of 579455 compute units","Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success","Program MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr invoke [1]","Program log: Memo (len 8): \"transfer\"","Program MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr consumed 4273 of 573255 compute units","Program MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr success"],"postBalances":[4441042119,1463843,2039280,2039280,0,182698617139,1,934087680,1009200,731913600,521498880],"postTokenBalances":[{"accountIndex":2,"mint":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","owner":"3i476kTBBTy7pBGx4CXwJpJ6phuwLQgcwLTdHhU3c7ui","programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","uiTokenAmount":{"amount":"1000","decimals":6,"uiAmount":0.001,"uiAmountString":"0.001"}},{"accountIndex":3,"mint":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","owner":"8fusVwhgo4oS1fGpZKeRaXrJXQk9auKnAgcj9A97wR3t","programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","uiTokenAmount":{"amount":"4847","decimals":6,"uiAmount":0.004847,"uiAmountString":"0.004847"}}],"preBalances":[4443091399,1463843,0,2039280,0,182698617139,1,934087680,1009200,731913600,521498880],"preTokenBalances":[{"accountIndex":3,"mint":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","owner":"8fusVwhgo4oS1fGpZKeRaXrJXQk9auKnAgcj9A97wR3t","programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","uiTokenAmount":{"amount":"5847","decimals":6,"uiAmount":0.005847,"uiAmountString":"0.005847"}}],"rewards":[],"status":{"Ok":null}},"slot":184930610,"transaction":{"message":{"accountKeys":[{"pubkey":"FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT","signer":true,"source":"transaction","writable":true},{"pubkey":"8fusVwhgo4oS1fGpZKeRaXrJXQk9auKnAgcj9A97wR3t","signer":true,"source":"transaction","writable":false},{"pubkey":"H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh","signer":false,"source":"transaction","writable":true},{"pubkey":"9rB2Poc468mPpY9WMUmaqEPsvJah8SpPB8bKqAjjXp5H","signer":false,"source":"transaction","writable":true},{"pubkey":"3i476kTBBTy7pBGx4CXwJpJ6phuwLQgcwLTdHhU3c7ui","signer":false,"source":"transaction","writable":false},{"pubkey":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","signer":false,"source":"transaction","writable":false},{"pubkey":"11111111111111111111111111111111","signer":false,"source":"transaction","writable":false},{"pubkey":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","signer":false,"source":"transaction","writable":false},{"pubkey":"SysvarRent111111111111111111111111111111111","signer":false,"source":"transaction","writable":false},{"pubkey":"ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL","signer":false,"source":"transaction","writable":false},{"pubkey":"MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr","signer":false,"source":"transaction","writable":false}],"addressTableLookups":null,"instructions":[{"parsed":{"info":{"account":"H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh","mint":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","source":"FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT","systemProgram":"11111111111111111111111111111111","tokenProgram":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","wallet":"3i476kTBBTy7pBGx4CXwJpJ6phuwLQgcwLTdHhU3c7ui"},"type":"create"},"program":"spl-associated-token-account","programId":"ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"},{"parsed":{"info":{"authority":"8fusVwhgo4oS1fGpZKeRaXrJXQk9auKnAgcj9A97wR3t","destination":"H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh","mint":"EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v","source":"9rB2Poc468mPpY9WMUmaqEPsvJah8SpPB8bKqAjjXp5H","tokenAmount":{"amount":"1000","decimals":6,"uiAmount":0.001,"uiAmountString":"0.001"}},"type":"transferChecked"},"program":"spl-token","programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"},{"parsed":"transfer","program":"spl-memo","programId":"MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"}],"recentBlockhash":"ERKtoPEssoWULPiUVGNLGMkR75EKkhN2VGbNgcQRGtXo"},"signatures":["2S2rTZjaqzxYRw9mnqzwtyqitKtSsnE8GVqLn1KrD5R2YpXZnU4GdjppsgfSAbrzJfaqadfi8CtrqEBy588WVQ3E","5kSm7znZGoZEy4u5q6H3JYDzxk1Bd6eoPsqacBfDwbWdSW3MHWxXgHNudxGu8kCFyQm8hTRufh7soNR56LxwzfSS"]}},"id":1}"#
}

var validGetSendSOLTransactionResponse: String {
    #"{"jsonrpc":"2.0","result":{"blockTime":1680146043,"meta":{"err":null,"fee":10000,"innerInstructions":[],"logMessages":["Program 11111111111111111111111111111111 invoke [1]","Program 11111111111111111111111111111111 success","Program MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr invoke [1]","Program log: Memo (len 8): \"transfer\"","Program MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr consumed 4273 of 400000 compute units","Program MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr success"],"postBalances":[4421621439,8257455,1000000,1,521498880],"postTokenBalances":[],"preBalances":[4421631439,9257455,0,1,521498880],"preTokenBalances":[],"rewards":[],"status":{"Ok":null}},"slot":185471096,"transaction":{"message":{"accountKeys":[{"pubkey":"FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT","signer":true,"source":"transaction","writable":true},{"pubkey":"DT1mBDFsNBc1UXa25RdxNvnjL5Lro7su7gX1zpLyCmWe","signer":true,"source":"transaction","writable":true},{"pubkey":"2b7iQq3PbWwWTotRSDFNXT9DauU418aCHK4jcAzETUem","signer":false,"source":"transaction","writable":true},{"pubkey":"11111111111111111111111111111111","signer":false,"source":"transaction","writable":false},{"pubkey":"MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr","signer":false,"source":"transaction","writable":false}],"addressTableLookups":null,"instructions":[{"parsed":{"info":{"destination":"2b7iQq3PbWwWTotRSDFNXT9DauU418aCHK4jcAzETUem","lamports":1000000,"source":"DT1mBDFsNBc1UXa25RdxNvnjL5Lro7su7gX1zpLyCmWe"},"type":"transfer"},"program":"system","programId":"11111111111111111111111111111111"},{"parsed":"transfer","program":"spl-memo","programId":"MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"}],"recentBlockhash":"AZgTFWYaZHm1jbt3HhBbJrku3RJtHdvcUARyggbZYaMo"},"signatures":["5QMfuqThWSMMpLCRe3tk7qn7iSwWKfJV8EvD1ZPvyqAWa7Z2JftZ4rPq8YCxCwzSykX7dMkDB8RrovQMoL9ZZWKY","4ymeFSeDfz3qF5GF4UAMZ9sxqV6oJ6nWbaSPF8D4yMotAzcJ3WXQDpEFRrJwqaqRXf8FmcWZS5YQs9UqS6DrjPca"]}},"id":1}"#
}

var validGetTokenAccountsByOwnerResponse: String {
    #"{"jsonrpc":"2.0","result":{"context":{"apiVersion":"1.14.16","slot":185442861},"value":[{"account":{"data":["xvp6877brTo9ZfNqq8l0MbG75MLS9uDkfKYCA0UvXWEoO7KykyTKouK3VAmnOYTNC9j95wsNSxw6JcnHlROmQegDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","base64"],"executable":false,"lamports":2039280,"owner":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","rentEpoch":0},"pubkey":"H51DXRt3ubThhdhNeDMScfkbC5X4AWzYfHaZS3JKEfPh"}]},"id":1}"#
}

var validGetTokenAccountBalanceResponse: String {
    #"{"jsonrpc":"2.0","result":{"context":{"apiVersion":"1.13.6","slot":185443407},"value":{"amount":"1000","decimals":6,"uiAmount":0.001,"uiAmountString":"0.001"}},"id":1}"#
}
