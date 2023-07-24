import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeyAppKitLogger
import Resolver
import Send
import SolanaSwift
import UIKit
import Wormhole

// MARK: - Singleton

extension DefaultLogManager {
    static let shared: DefaultLogManager = {
        let manager = DefaultLogManager()
        SolanaSwift.Logger.setLoggers([manager])
        FeeRelayerSwift.Logger.setLoggers([manager])
        KeyAppKitLogger.Logger.setLoggers([manager])
        return manager
    }()
}

// MARK: - Convenience methods

extension DefaultLogManager: SolanaSwiftLogger,
    FeeRelayerSwiftLogger,
    KeyAppKitLoggerType,
    KeyAppKitCore.ErrorObserver
{
    func log(event: String, data: String?, logLevel: DefaultLogLevel) {
        var newLogLevel: DefaultLogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        case .request:
            newLogLevel = .request
        case .response:
            newLogLevel = .response
        case .event:
            newLogLevel = .event
        case .alert:
            newLogLevel = .alert
        }

        providers.forEach { logger in
            guard logger.supportedLogLevels.contains(newLogLevel) else { return }
            log(event: event, logLevel: newLogLevel, data: data)
        }
    }

    func log(event: String, data: String?, logLevel: SolanaSwift.SolanaSwiftLoggerLogLevel) {
        var newLogLevel: DefaultLogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }

        log(event: event, data: data, logLevel: newLogLevel)
    }

    func log(event: String, data: String?, logLevel: FeeRelayerSwift.FeeRelayerSwiftLoggerLogLevel) {
        var newLogLevel: DefaultLogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }
        log(event: event, data: data, logLevel: newLogLevel)
    }

    func log(event: String, data: String?, logLevel: KeyAppKitLogger.KeyAppKitLoggerLogLevel) {
        var newLogLevel: DefaultLogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }
        log(event: event, data: data, logLevel: newLogLevel)
    }

    func handleError(_ error: Error, config: ErrorObserverConfig?) {
        let config = config ?? .init(flags: [])

        // Default log
        log(event: config.domain ?? "Error", logLevel: .error, data: String(reflecting: error))

        // Realtime log
        if config.flags.contains(.realtimeAlert) {
            // Setup
            let log: [String: Any] = [
                "platform": "iOS \(UIDevice.current.systemVersion)",
                "userPubkey": Resolver.resolve(UserWalletManager.self).wallet?.account.publicKey
                    .base58EncodedString ?? "",
                "appVersion": AppInfo.appVersionDetail,
                "timestamp": "\(Int64(Date().timeIntervalSince1970 * 1000))",
                "error": error.localizedDescription,
            ]

            let logStr: String
            if
                let logData = try? JSONSerialization.data(withJSONObject: log),
                let log = String(data: logData, encoding: .utf8)
            {
                logStr = log
            } else {
                logStr = String(reflecting: log)
            }

            self.log(event: "\(config.domain ?? "General") iOS Alarm", logLevel: .alert, data: logStr)
        }
    }

    func handleError(_ error: Error, userInfo: [String: Any]?) {
        guard let error = error as? UserActionError else {
            return
        }

        Task {
            let data = await AlertLoggerDataBuilder.buildLoggerData(error: error)
            let accountStorage: UserWalletManager = Resolver.resolve()
            // Claim
            if error.domain == WormholeClaimUserActionError.domain,
               let action =
               userInfo?[WormholeClaimUserActionError.UserInfoKey.action.rawValue] as? WormholeClaimUserAction
            {
                let message = ClaimAlertLoggerErrorMessage(
                    tokenToClaim: .init(
                        name: action.token.name,
                        solanaMint: SupportedToken.ERC20(rawValue: action.token.erc20Address ?? "")?
                            .solanaMintAddress ?? "",
                        ethMint: action.token.tokenPrimaryKey,
                        claimAmount: CryptoFormatter().string(amount: action.amountInCrypto)
                    ),
                    userPubkey: data.userPubkey,
                    userEthPubkey: accountStorage.wallet?.ethAddress ?? "",
                    simulationError: error == WormholeClaimUserActionError.submitError ? error
                        .localizedDescription : nil,
                    bridgeSeviceError: error != WormholeClaimUserActionError.submitError ? error
                        .localizedDescription : nil,
                    blockchainError: nil
                )
                self.log(event: "Wormhole Claim iOS Alarm", logLevel: .alert, data: message)
            } else if error.domain == WormholeSendUserActionError.domain,
                      let action =
                      userInfo?[WormholeClaimUserActionError.UserInfoKey.action.rawValue] as? WormholeSendUserAction
            {
                let simulationError: String? = {
                    if error != WormholeSendUserActionError.feeRelaySignFailure && error != WormholeSendUserActionError
                        .submittingToBlockchainFailure
                    {
                        return error.readableDescription
                    }
                    return nil
                }()
                let message = SendWormholeAlertLoggerErrorMessage(
                    tokenToSend: .init(
                        name: action.sourceToken.name,
                        mint: action.sourceToken.tokenPrimaryKey,
                        sendAmount: CryptoFormatter().string(amount: action.amount)
                    ),
                    arbiterFeeAmount: action.fees.arbiter?.amount ?? "",
                    userPubkey: data.userPubkey,
                    recipientEthPubkey: action.recipient,
                    simulationError: simulationError,
                    feeRelayerError: error == WormholeSendUserActionError.feeRelaySignFailure ? error
                        .readableDescription : nil,
                    blockchainError: error == WormholeSendUserActionError.submittingToBlockchainFailure ? error
                        .readableDescription : nil
                )
                self.log(event: "Wormhole Send iOS Alarm", logLevel: .alert, data: message)
            }
        }
    }
}
