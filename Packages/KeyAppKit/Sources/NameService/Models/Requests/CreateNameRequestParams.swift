import Foundation
import SolanaSwift

struct CreateNameRequestMessage: Codable, BorshSerializable {
    let owner: String
    let timestamp: Int64

    func serialize(to writer: inout Data) throws {
        try owner.serialize(to: &writer)
        try timestamp.serialize(to: &writer)
    }
}

struct CreateNameRequestParams: Codable {
    let name: String
    let owner: String
    let credentials: Credentials

    struct Credentials: Codable {
        let timestamp: Date
        let signature: String
    }
}

// TODO: Tech debt. Old structure which will be used when user is not authorized with web3auth
public struct PostParams: Encodable {
    public init(owner: String, credentials: PostParams.Credentials) {
        self.owner = owner
        self.credentials = credentials
    }

    public let owner: String
    public let credentials: Credentials

    public struct Credentials: Encodable {
        public init(geetest_validate: String, geetest_seccode: String, geetest_challenge: String) {
            self.geetest_validate = geetest_validate
            self.geetest_seccode = geetest_seccode
            self.geetest_challenge = geetest_challenge
        }

        let geetest_validate: String
        let geetest_seccode: String
        let geetest_challenge: String
    }
}

public struct PostResponse: Decodable {
    public let signature: String
}

