import Foundation
import KeyAppBusiness
import KeyAppNetworking
import Resolver
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
    var referrer: String {
        nameStorage.getName() ?? currentUserAddress
    }

    var shareLink: URL {
        URL(string: "https://r.key.app/\(referrer)")!
    }

    func setReferent(from: String) async throws -> String {
        guard let secret = userWallet.wallet?.account.secretKey else { throw ReferralProgramServiceError.failedSet }
        var timestamp = Date().timeIntervalSince1970
        let model = ReferralSetReferentModel(user: currentUserAddress, referent: referrer, timestamp: timestamp)
        let data = try JSONEncoder().encode(model)
        let signed = try NaclSign.signDetached(message: data, secretKey: secret)
        return try await jsonrpcClient.request(
            baseURL: baseURL,
            body: .init(
                method: "set_referent",
                params: ReferralSetReferentRequest(
                    user: currentUserAddress,
                    referent: from,
                    timedSignature: .init(
                        timestamp: timestamp,
                        signature: signed.base64EncodedString()
                    )
                )
            )
        )
    }
}

private struct ReferralSetReferentRequest: Encodable {
    struct TimedSignature: Encodable {
        let timestamp: TimeInterval
        let signature: String
    }

    let user: String
    let referent: String
    let timedSignature: TimedSignature

    enum CodingKeys: String, CodingKey {
        case user, referent, timedSignature = "timed_signature"
    }
}

private struct ReferralSetReferentModel: Encodable {
    let user: String
    let referent: String
    let timestamp: TimeInterval
}
