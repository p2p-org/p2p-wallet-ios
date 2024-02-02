import Foundation
import SolanaSwift
import TweetNacl

struct SetReferentRequest: Encodable {
    let user: String
    let referent: String
    let timedSignature: ReferralTimedSignature

    enum CodingKeys: String, CodingKey {
        case user, referent, timedSignature = "timed_signature"
    }
}

struct SetReferentSignature: BorshSerializable {
    let user: String
    let referent: String
    let timestamp: Int64

    func serialize(to writer: inout Data) throws {
        try user.serialize(to: &writer)
        try referent.serialize(to: &writer)
        try timestamp.serialize(to: &writer)
    }

    func sign(secretKey: Data) throws -> Data {
        var data = Data()
        try serialize(to: &data)
        return try NaclSign.signDetached(message: data, secretKey: secretKey)
    }
}
