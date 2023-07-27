import Foundation

// MARK: - RelayTests
struct RelayTestsInfo: Codable {
    let baseUrlString: String
    let topUp: RelayTopUpTest?
    let solToSPL: RelaySwapTestInfo?
    let splToSOL: RelaySwapTestInfo?
    let splToCreatedSpl: RelaySwapTestInfo?
    let splToNonCreatedSpl: RelaySwapTestInfo?
    let usdtTransfer: RelayTransferTestInfo?
    let usdtBackTransfer: RelayTransferTestInfo?
    let usdtTransferToNonCreatedToken: RelayTransferTestInfo?
    let relaySendNativeSOL: RelayTransferNativeSOLTestInfo?
}

protocol RelayTestType {
    var endpoint: String {get}
    var endpointAdditionalQuery: String? {get}
    var seedPhrase: String {get}
}

// MARK: - TopUpTest
struct RelayTopUpTest: Codable, RelayTestType {
    let endpoint: String
    let endpointAdditionalQuery: String?
    let seedPhrase, payingTokenMint, payingTokenAddress: String
    let amount: UInt64
}

// MARK: - SplToCreatedSpl
struct RelaySwapTestInfo: Codable, RelayTestType {
    let endpoint: String
    let endpointAdditionalQuery: String?
    let seedPhrase, fromMint, toMint: String
    let sourceAddress, payingTokenMint, payingTokenAddress: String
    let destinationAddress: String?
    let inputAmount: UInt64
    let slippage: Double
}

struct RelayTransferTestInfo: Codable, RelayTestType {
    let endpoint: String
    let endpointAdditionalQuery: String?
    let seedPhrase, mint: String
    let sourceTokenAddress, destinationAddress: String
    let inputAmount, expectedFee: UInt64
    let payingTokenAddress: String
    let payingTokenMint: String
}

struct RelayTransferNativeSOLTestInfo: Codable, RelayTestType {
    let endpoint: String
    let endpointAdditionalQuery: String?
    let seedPhrase, destination: String
    let inputAmount, expectedFee: UInt64
    let payingTokenAddress, payingTokenMint: String
}
