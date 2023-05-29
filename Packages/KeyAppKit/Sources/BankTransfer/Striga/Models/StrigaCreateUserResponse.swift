import Foundation

public struct StrigaCreateUserResponse: Decodable {
    let userId: String
    let email: String
    let KYC: KYC
    
    struct KYC: Decodable {
        let status: String
    }
}
