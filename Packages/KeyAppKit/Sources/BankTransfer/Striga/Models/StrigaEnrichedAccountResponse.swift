import Foundation

public struct StrigaEnrichedEURAccountResponse: Codable, Equatable {
    public let currency: String
    public let status: String
    public let internalAccountId: String
    public let bankCountry: String
    public let bankAddress: String
    public let iban: String
    public let bic: String
    public let accountNumber: String
    public let bankName: String
    public let bankAccountHolderName: String
    public let provider: String
    public let domestic: Bool
}

public struct StrigaEnrichedUSDCAccountResponse: Codable, Equatable {
    public let blockchainDepositAddress: String
    public let blockchainNetwork: BlockchainNetwork

    public struct BlockchainNetwork: Codable, Equatable {
        public let name: String
        public let type: String
        public let contractAddress: String
    }
}
