import Foundation

public struct StrigaTransactionConfirmOTPResponse: Codable {
    let id: String
    let amount: String
    let feeSats: String
    let invoice: String
    let payeeNode: String
    let network: Network
    
    struct Network: Codable {
        let bech32: String
        let pubKeyHash: Int
        let scriptHash: Int
        let validWitnessVersions: [Int]
    }
}
