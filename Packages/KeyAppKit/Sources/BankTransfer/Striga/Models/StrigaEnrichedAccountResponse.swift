import Foundation

public struct StrigaEnrichedAccountResponse: Codable, Equatable {
    public let blockchainDepositAddress: String
    public let blockchainNetwork: BlockchainNetwork
    
    public struct BlockchainNetwork: Codable, Equatable {
        public let name: String
        public let type: String
        public let contractAddress: String
    }
}
