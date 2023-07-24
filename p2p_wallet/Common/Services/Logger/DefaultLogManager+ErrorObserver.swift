import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send
import UIKit
import Wormhole

extension DefaultLogManager: KeyAppKitCore.ErrorObserver {
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
                        ethMint: action.token.id,
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
                        mint: action.sourceToken.id,
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
