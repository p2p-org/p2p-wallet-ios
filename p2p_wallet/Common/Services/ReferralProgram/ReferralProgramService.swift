import Foundation
import KeyAppBusiness
import KeyAppNetworking
import Resolver
import SolanaSwift
import Task_retrying
import TweetNacl

protocol ReferralProgramService {
    var referrer: String { get }
    var shareLink: URL { get }

    func register() async
    func setReferent(from: String) async
}

enum ReferralProgramServiceError: Error {
    case unauthorized
    case timeOut
    case alreadyRegistered
    case other
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
            try await Task.retrying(
                where: { $0.isRetryable },
                maxRetryCount: 10,
                retryDelay: 5, // 5 secs
                timeoutInSeconds: 60, // wait for 60s if no success then throw .timedOut error
                operation: { [weak self] _ in
                    // if there is transaction, send it
                    try await self?.sendRegisterRequest()
                }
            ).value
        } catch {
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
            guard let secret = userWallet.wallet?.account.secretKey
            else { throw ReferralProgramServiceError.unauthorized }
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

    private func sendRegisterRequest() async throws {
        do {
            guard let secret = userWallet.wallet?.account.secretKey
            else { throw ReferralProgramServiceError.unauthorized }
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
            if error.localizedDescription.contains("duplicate key value violates unique constraint") {
                // The code is not unique so we look at the description
                Defaults.referrerRegistered = true
                throw ReferralProgramServiceError.alreadyRegistered
            }
            if error.localizedDescription.contains("timed out") || (error as NSError).code == NSURLErrorTimedOut {
                throw ReferralProgramServiceError.timeOut
            }
            throw ReferralProgramServiceError.other
        }
    }
}

// MARK: - Helpers

private extension Swift.Error {
    var isRetryable: Bool {
        switch self {
        case let error as ReferralProgramServiceError:
            switch error {
            case .timeOut:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
