import Foundation
import KeyAppBusiness
import KeyAppNetworking
import Resolver
import SolanaSwift
import TweetNacl

protocol ReferralProgramService {
    var referrer: String { get }
    var shareLink: URL { get }

    func register() async
    func setReferent(from: String) async
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

    func register() async {
        guard !Defaults.referrerRegistered else { return }
        do {
            guard let secret = userWallet.wallet?.account.secretKey else { throw ReferralProgramServiceError.failedSet }
            let timestamp = Int64(Date().timeIntervalSince1970)
            let signed = try RegisterUserSignature(
                user: currentUserAddress, referrent: nil, timestamp: timestamp
            )
            .sign(secretKey: secret)
            let _: String? = try await jsonrpcClient.request(
                baseURL: baseURL,
                body: .init(
                    method: "register",
                    params: RegisterUserRequest(
                        user: currentUserAddress,
                        timedSignature: ReferralTimedSignature(
                            timestamp: timestamp, signature: signed.toHexString()
                        )
                    )
                )
            )
            Defaults.referrerRegistered = true
        } catch {
            debugPrint(error)
            DefaultLogManager.shared.log(
                event: "\(ReferralProgramService.self)_register",
                data: error.localizedDescription,
                logLevel: LogLevel.error
            )
        }
    }

    func setReferent(from: String) async {
        guard from != currentUserAddress else { return }
        do {
            guard let secret = userWallet.wallet?.account.secretKey else { throw ReferralProgramServiceError.failedSet }
            let timestamp = Int64(Date().timeIntervalSince1970)
            let signed = try SetReferentSignature(
                user: currentUserAddress, referent: from, timestamp: timestamp
            )
            .sign(secretKey: secret)
            let _: String? = try await jsonrpcClient.request(
                baseURL: baseURL,
                body: .init(
                    method: "set_referent",
                    params: SetReferentRequest(
                        user: currentUserAddress,
                        referent: from,
                        timedSignature: ReferralTimedSignature(
                            timestamp: timestamp,
                            signature: signed.toHexString()
                        )
                    )
                )
            )
        } catch {
            debugPrint(error)
            DefaultLogManager.shared.log(
                event: "\(ReferralProgramService.self)_setReferent",
                data: error.localizedDescription,
                logLevel: LogLevel.error
            )
        }
    }
}
