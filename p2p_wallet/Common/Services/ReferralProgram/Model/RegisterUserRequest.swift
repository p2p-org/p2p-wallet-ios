import Foundation
import SolanaSwift
import TweetNacl

struct RegisterUserRequest: Encodable {
    let user: String
    let timedSignature: ReferralTimedSignature

    enum CodingKeys: String, CodingKey {
        case user, timedSignature = "timed_signature"
    }
}

struct RegisterUserSignature: BorshSerializable {
    let user: String
    let referrent: String?
    let timestamp: Int64

    func serialize(to writer: inout Data) throws {
        try user.serialize(to: &writer)
        try Optional(referrent)?.serialize(to: &writer)
        try timestamp.serialize(to: &writer)
    }

    func sign(secretKey: Data) throws -> Data {
        var data = Data()
        try serialize(to: &data)
        return try NaclSign.signDetached(message: data, secretKey: secretKey)
    }
}
