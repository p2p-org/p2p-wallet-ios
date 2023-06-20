import Foundation

public struct StrigaWalletSendResponse: Codable {
    let challengeId: String
    let dateExpires: String
    let transaction: Transaction
    let feeEstimate: FeeEstimate

    struct Transaction: Codable {
        let syncedOwnerId: String
        let sourceAccountId: String
        let parentWalletId: String
        let currency: String
        let amount: String
        let status: String
        let txType: String
        let blockchainDestinationAddress: String
        let blockchainNetwork: BlockchainNetwork
        let transactionCurrency: String

        struct BlockchainNetwork: Codable {
            let name: String
        }
    }

    struct FeeEstimate: Codable {
        let totalFee: String
        let networkFee: String
        let ourFee: String
        let theirFee: String
        let feeCurrency: String
        let gasLimit: String
        let gasPrice: String
    }
}

