// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import CryptoKit
import Foundation
import SolanaSwift
import TweetNacl

public typealias BindingPhoneNumberChannel = APIGatewayChannel

public enum BindingPhoneNumberResult: Codable, Equatable {
    case success(metadata: WalletMetaData)
    case breakProcess
}

public enum BindingPhoneNumberEvent {
    case enterPhoneNumber(phoneNumber: String, channel: BindingPhoneNumberChannel)
    case enterOTP(opt: String)
    case resendOTP
    case blockFinish
    case home
    case back
}

public struct BindingPhoneNumberData: Codable, Equatable {
    let seedPhrase: String
    let ethAddress: String
    let customShare: String
    let payload: String

    let deviceName: String
    let email: String
    let authProvider: String

    var sendingThrottle: Throttle = .init(maxAttempt: 5, timeInterval: 60 * 10)
}

public enum BindingPhoneNumberState: Codable, State, Equatable {
    public typealias Event = BindingPhoneNumberEvent
    public typealias Provider = APIGatewayClient

    case enterPhoneNumber(
        initialPhoneNumber: String?,
        didSend: Bool,
        resendCounter: Wrapper<ResendCounter>?,
        data: BindingPhoneNumberData
    )
    case enterOTP(
        resendCounter: Wrapper<ResendCounter>,
        channel: BindingPhoneNumberChannel,
        phoneNumber: String,
        data: BindingPhoneNumberData
    )
    case block(until: Date, reason: PhoneFlowBlockReason, phoneNumber: String, data: BindingPhoneNumberData)
    case broken(code: Int)
    case finish(_ result: BindingPhoneNumberResult)

    public static var initialState: BindingPhoneNumberState = .enterPhoneNumber(
        initialPhoneNumber: nil,
        didSend: false,
        resendCounter: nil,
        data: .init(
            seedPhrase: "",
            ethAddress: "",
            customShare: "",
            payload: "",
            deviceName: "",
            email: "",
            authProvider: ""
        )
    )

    public func accept(
        currentState: BindingPhoneNumberState,
        event: BindingPhoneNumberEvent,
        provider: APIGatewayClient
    ) async throws -> BindingPhoneNumberState {
        switch currentState {
        case let .enterPhoneNumber(initialPhoneNumber, didSend, resendCounter, data):
            switch event {
            case let .enterPhoneNumber(phoneNumber, channel):
                if initialPhoneNumber == phoneNumber, didSend {
                    return .enterOTP(
                        resendCounter: resendCounter ?? .init(.zero()),
                        channel: .sms,
                        phoneNumber: phoneNumber,
                        data: data
                    )
                }

                if !data.sendingThrottle.process() {
                    data.sendingThrottle.reset()
                    return .block(
                        until: Date() + blockTime,
                        reason: .blockEnterPhoneNumber,
                        phoneNumber: phoneNumber,
                        data: data
                    )
                }

                let account = try await Account(
                    phrase: data.seedPhrase.components(separatedBy: " "),
                    network: .mainnetBeta,
                    derivablePath: .default
                )

                do {
                    try await provider.registerWallet(
                        solanaPrivateKey: Base58.encode(account.secretKey),
                        ethAddress: data.ethAddress,
                        phone: phoneNumber,
                        channel: channel,
                        timestampDevice: Date()
                    )

                    return .enterOTP(
                        resendCounter: .init(.zero()),
                        channel: channel,
                        phoneNumber: phoneNumber,
                        data: data
                    )
                } catch let error as APIGatewayError {
                    switch error._code {
                    case -32058, -32700, -32600, -32601, -32602, -32603, -32052:
                        return .broken(code: error._code)
                    default:
                        throw error
                    }
                } catch let error as APIGatewayCooldownError {
                    data.sendingThrottle.reset()
                    return .block(
                        until: Date() + error.cooldown,
                        reason: .blockEnterPhoneNumber,
                        phoneNumber: phoneNumber,
                        data: data
                    )
                }
            default:
                throw StateMachineError.invalidEvent
            }
        case let .enterOTP(resendCounter, channel, phoneNumber, data):
            switch event {
            case let .enterOTP(opt):
                let account = try await Account(
                    phrase: data.seedPhrase.components(separatedBy: " "),
                    network: .mainnetBeta,
                    derivablePath: .default
                )

                let metaData = WalletMetaData(
                    deviceName: data.deviceName,
                    email: data.email,
                    authProvider: data.authProvider,
                    phoneNumber: phoneNumber
                )

                do {
                    try await provider.confirmRegisterWallet(
                        solanaPrivateKey: Base58.encode(account.secretKey),
                        ethAddress: data.ethAddress,
                        share: data.customShare,
                        encryptedPayload: data.payload,
                        encryptedMetaData: try metaData.encrypt(seedPhrase: data.seedPhrase),
                        phone: phoneNumber,
                        otpCode: opt,
                        timestampDevice: Date()
                    )
                } catch let error as APIGatewayError {
                    switch error._code {
                    case -32058, -32700, -32600, -32601, -32602, -32603, -32052:
                        return .broken(code: error._code)
                    default:
                        throw error
                    }
                } catch let error as APIGatewayCooldownError {
                    return .block(
                        until: Date() + error.cooldown,
                        reason: .blockEnterOTP,
                        phoneNumber: phoneNumber,
                        data: data
                    )
                }

                return .finish(.success(metadata: metaData))
            case .resendOTP:
                let account = try await Account(
                    phrase: data.seedPhrase.components(separatedBy: " "),
                    network: .mainnetBeta,
                    derivablePath: .default
                )

                do {
                    try await provider.registerWallet(
                        solanaPrivateKey: Base58.encode(account.secretKey),
                        ethAddress: data.ethAddress,
                        phone: phoneNumber,
                        channel: channel,
                        timestampDevice: Date()
                    )
                    resendCounter.value = resendCounter.value.incremented()
                    return currentState
                } catch let error as APIGatewayError {
                    switch error._code {
                    case -32058, -32700, -32600, -32601, -32602, -32603, -32052:
                        return .broken(code: error._code)
                    default:
                        throw error
                    }
                } catch let error as APIGatewayCooldownError {
                    return .block(
                        until: Date() + error.cooldown,
                        reason: .blockResend,
                        phoneNumber: phoneNumber,
                        data: data
                    )
                }
            case .back:
                return .enterPhoneNumber(
                    initialPhoneNumber: phoneNumber,
                    didSend: true,
                    resendCounter: resendCounter,
                    data: data
                )
            default:
                throw StateMachineError.invalidEvent
            }
        case .broken:
            switch event {
            case .back:
                return .finish(.breakProcess)
            default:
                throw StateMachineError.invalidEvent
            }
        case let .block(until, reason, phoneNumber, data):
            switch event {
            case .home:
                return .finish(.breakProcess)
            case .blockFinish:
                guard Date() > until else { throw StateMachineError.invalidEvent }
                switch reason {
                case .blockEnterPhoneNumber, .blockResend, .blockEnterOTP:
                    return .enterPhoneNumber(
                        initialPhoneNumber: phoneNumber,
                        didSend: false,
                        resendCounter: nil,
                        data: data
                    )
                }
            default: throw StateMachineError.invalidEvent
            }
        default:
            throw StateMachineError.invalidEvent
        }
    }
}

extension BindingPhoneNumberState: Step, Continuable {
    public var continuable: Bool {
        switch self {
        case .broken: return false
        default: return true
        }
    }

    public var step: Float {
        switch self {
        case .enterPhoneNumber:
            return 1
        case .enterOTP:
            return 2
        case .block:
            return 3
        case .broken:
            return 4
        case .finish:
            return 5
        }
    }
}
