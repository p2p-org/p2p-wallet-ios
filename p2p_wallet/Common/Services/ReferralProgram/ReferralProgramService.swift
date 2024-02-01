import Foundation
import KeyAppBusiness
import KeyAppNetworking
import Resolver
import SolanaSwift
import TweetNacl

protocol ReferralProgramService {
    var referrer: String { get }
    var shareLink: URL { get }

    func setReferent(from: String) async throws -> String
}

enum ReferralProgramServiceError: Error {
    case failedSet
}

final class ReferralProgramServiceImpl {
    // MARK: - Dependencies

    @Injected private var nameStorage: NameStorageType
    @Injected private var userWallet: UserWalletManager

    private let jsonrpcClient = JSONRPCHTTPClient()

    // MARK: - Private properties

    private var baseURL: String {
        GlobalAppState.shared.referralProgramAPIEndoint
    }

    private var currentUserAddress: String {
        userWallet.wallet?.account.publicKey.base58EncodedString ?? ""
    }
}

// MARK: - ReferralProgramService

extension ReferralProgramServiceImpl: ReferralProgramService {
    private struct SetReferentRequest: Encodable {
        struct TimedSignature: Encodable {
            let timestamp: Int64
            let signature: String
        }

        let user: String
        let referent: String
        let timedSignature: TimedSignature

        enum CodingKeys: String, CodingKey {
            case user, referent, timedSignature = "timed_signature"
        }
    }

    private struct SetReferentSignature: BorshSerializable {
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

        func signAsBase64(secretKey: Data) throws -> String {
            try sign(secretKey: secretKey).base64EncodedString()
        }
    }

    var referrer: String {
        nameStorage.getName() ?? currentUserAddress
    }

    var shareLink: URL {
        URL(string: "https://r.key.app/\(referrer)")!
    }

    func setReferent(from: String) async throws -> String {
        guard let secret = userWallet.wallet?.account.secretKey else { throw ReferralProgramServiceError.failedSet }
        var timestamp = Int64(Date().timeIntervalSince1970)
        let signed = try SetReferentSignature(user: currentUserAddress, referent: referrer, timestamp: timestamp)
            .signAsBase64(secretKey: secret)
        return try await jsonrpcClient.request(
            baseURL: baseURL,
            body: .init(
                method: "set_referent",
                params: SetReferentRequest(
                    user: currentUserAddress,
                    referent: from,
                    timedSignature: SetReferentRequest.TimedSignature(
                        timestamp: timestamp,
                        signature: signed
                    )
                )
            )
        )
    }
}
