import Foundation
import Send
import Wormhole
import KeyAppBusiness
import SolanaSwift
import FeeRelayerSwift
import KeyAppKitLogger
import KeyAppKitCore
import Resolver

enum LogLevel: String {
    case info
    case error
    case request
    case response
    case event
    case warning
    case debug
    case alert
}

protocol LogManagerLogger {
    var supportedLogLevels: [LogLevel] { get set }
    func log(event: String, logLevel: LogLevel, data: String?)
}

protocol LogManager {
    func setProviders(_ providers: [LogManagerLogger])
    func log(event: String, logLevel: LogLevel, data: String?, shouldLogEvent: (() -> Bool)?)
    func log(event: String, logLevel: LogLevel, data: (any Encodable)?)
}

class DefaultLogManager: LogManager {
    static let shared = DefaultLogManager()
    let dataFilter = DefaultSensitiveDataFilter()

    private(set) var providers: [LogManagerLogger] = []
    private var queue = DispatchQueue(label: "DefaultLogManager", qos: .utility, attributes: [.concurrent])

    func setProviders(_ providers: [LogManagerLogger] = [SentryLogger(), AlertLogger()]) {
        self.providers = providers
    }

    func log(event: String, logLevel: LogLevel, data: String? = nil, shouldLogEvent: (() -> Bool)? = nil) {
        guard shouldLogEvent?() ?? true else { return }
        providers.forEach { provider in
            guard provider.supportedLogLevels.contains(logLevel) else { return }
            queue.async {
                provider.log(event: event, logLevel: logLevel, data: self.dataFilter.map(string: data ?? ""))
            }
        }
    }

    func log(event: String, logLevel: LogLevel, data: (any Encodable)?) {
        log(event: event, logLevel: logLevel, data: data?.jsonString, shouldLogEvent: nil)
    }
    
    func log(error: Error) {
        // capture error
        if let error = error as? CustomNSError {
            log(event: "Error", logLevel: .error, data: error.errorUserInfo[NSDebugDescriptionErrorKey] as? String)
        }
        // else
        else {
            log(event: "Error", logLevel: .error, data: String(reflecting: error))
        }
    }
}

extension DefaultLogManager: SolanaSwiftLogger, FeeRelayerSwiftLogger, KeyAppKitLoggerType, KeyAppKitCore.ErrorObserver {

    func log(event: String, data: String?, logLevel: LogLevel) {
        var newLogLevel: LogLevel = .info
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
        
        self.providers.forEach { logger in
            guard logger.supportedLogLevels.contains(newLogLevel) else { return }
            log(event: event, logLevel: newLogLevel, data: data)
        }
    }
    
    func log(event: String, data: String?, logLevel: SolanaSwift.SolanaSwiftLoggerLogLevel) {
        var newLogLevel: LogLevel = .info
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
        var newLogLevel: LogLevel = .info
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
        var newLogLevel: LogLevel = .info
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

    func handleError(_ error: Error) {
        handleError(error, userInfo: nil)
    }

    func handleError(_ error: Error, userInfo: [String : Any]?) {
        guard let error = error as? UserActionError else {
            return
        }

        Task {
            let data = await AlertLoggerDataBuilder.buildLoggerData(error: error)
            let accountStorage: UserWalletManager = Resolver.resolve()
            // Claim
            if error.domain == WormholeClaimUserActionError.domain, let action = userInfo?[WormholeClaimUserActionError.UserInfoKey.action.rawValue] as? WormholeClaimUserAction {
                
                let message = ClaimAlertLoggerErrorMessage(
                    tokenToClaim: .init(
                        name: action.token.name,
                        solanaMint: SupportedToken.ERC20(rawValue: action.token.erc20Address ?? "")?.solanaMintAddress ?? "",
                        ethMint: action.token.tokenPrimaryKey,
                        claimAmount: CryptoFormatter().string(amount: action.amountInCrypto)
                    ),
                    userPubkey: data.userPubkey,
                    userEthPubkey: accountStorage.wallet?.ethAddress ?? "",
                    simulationError: error == WormholeClaimUserActionError.submitError ? error.localizedDescription : nil,
                    bridgeSeviceError: error != WormholeClaimUserActionError.submitError ? error.localizedDescription : nil,
                    blockchainError: nil
                )
                self.log(event: "Wormhole Claim iOS Alarm", logLevel: .alert, data: message)
            } else if error.domain == WormholeSendUserActionError.domain, let action = userInfo?[WormholeClaimUserActionError.UserInfoKey.action.rawValue] as? WormholeSendUserAction {
                let simulationError: String? = {
                    if error != WormholeSendUserActionError.feeRelaySignFailure && error != WormholeSendUserActionError.submittingToBlockchainFailure {
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
                    feeRelayerError: error == WormholeSendUserActionError.feeRelaySignFailure ? error.readableDescription : nil,
                    blockchainError: error == WormholeSendUserActionError.submittingToBlockchainFailure ? error.readableDescription : nil
                )
                self.log(event: "Wormhole Send iOS Alarm", logLevel: .alert, data: message)
            }
        }
    }

}

protocol SensitiveDataFilterRule {
    func map(_ string: String) -> String
}

protocol SensitiveDataFilter {
    var rules: [SensitiveDataFilterRule] { get }
    func map(string: String) -> String
    func map(data: [AnyHashable: AnyHashable]) -> [AnyHashable: AnyHashable]
}

struct PrivateKeySensitiveDataFilterRule: SensitiveDataFilterRule {
    let placeholder = "<SensitiveDataFilter>"
    let regs = ["[1-9A-HJ-NP-Za-km-z]{87}", "0x[a-fA-F0-9]{64}"]

    func map(_ string: String) -> String {
        var str = string
        regs.forEach { reg in
            guard let regex = try? NSRegularExpression(pattern: reg, options: NSRegularExpression.Options.caseInsensitive) else {
                return
            }
            let range = NSMakeRange(0, string.count)
            let modString = regex.stringByReplacingMatches(
                in: string, options: [], range: range, withTemplate: placeholder
            )
            str = modString
        }
        return str
    }
}

class DefaultSensitiveDataFilter: SensitiveDataFilter {
    var rules: [SensitiveDataFilterRule] = [PrivateKeySensitiveDataFilterRule()]

    func map(string: String) -> String {
        var ret = string
        rules.forEach { rule in
            ret = rule.map(ret)
        }
        return ret
    }

    func map(data: [AnyHashable: AnyHashable]) -> [AnyHashable: AnyHashable] {
        var newData = data
        data.keys.forEach { key in
            if let value = data[key] as? String {
                newData[key] = self.map(string: value)
            }
        }
        return newData
    }
}
