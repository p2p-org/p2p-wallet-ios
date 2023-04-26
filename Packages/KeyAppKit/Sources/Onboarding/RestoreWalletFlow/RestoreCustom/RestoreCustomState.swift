// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import TweetNacl

public typealias RestoreCustomChannel = APIGatewayChannel

public enum RestoreCustomResult: Codable, Equatable {
    case successful(
        seedPhrase: String,
        ethPublicKey: String,
        metadata: WalletMetaData?
    )
    case requireSocialCustom(result: APIGatewayRestoreWalletResult)
    case requireSocialDevice(provider: SocialProvider, result: APIGatewayRestoreWalletResult?)
    case start
    case breakProcess
}

public enum RestoreCustomEvent {
    case enterPhone
    case enterPhoneNumber(phone: String)
    case enterOTP(otp: String)
    case resendOTP
    case requireSocial(provider: SocialProvider)
    case start
    case back
}

public struct RestoreCustomContainer {
    let tKeyFacade: TKeyFacade
    let apiGatewayClient: APIGatewayClient
    let authService: SocialAuthService
    let deviceShare: String?
}

public enum RestoreCustomState: Codable, State, Equatable {
    public typealias Event = RestoreCustomEvent
    public typealias Provider = RestoreCustomContainer

    case enterPhone(
        initialPhoneNumber: String?,
        didSend: Bool,
        resendCounter: Wrapper<ResendCounter>?,
        solPrivateKey: Data?,
        social: RestoreSocialData?
    )
    case enterOTP(phone: String, solPrivateKey: Data, social: RestoreSocialData?, attempt: Wrapper<ResendCounter>)
    case otpNotDeliveredTrySocial(phone: String, code: Int)
    case otpNotDelivered(phone: String, code: Int)
    case noMatch
    case notFoundDevice(result: APIGatewayRestoreWalletResult)
    case tryAnother(wrongNumber: String, trySocial: Bool)
    case broken(code: Int)
    case block(until: Date, social: RestoreSocialData?, reason: PhoneFlowBlockReason)
    case finish(result: RestoreCustomResult)

    public static var initialState: RestoreCustomState = .enterPhone(
        initialPhoneNumber: nil,
        didSend: false,
        resendCounter: nil,
        solPrivateKey: nil,
        social: nil
    )

    public func accept(
        currentState: RestoreCustomState,
        event: RestoreCustomEvent,
        provider: RestoreCustomContainer
    ) async throws -> RestoreCustomState {
        switch currentState {
        case let .enterPhone(initialPhoneNumber, didSend, resendCounter, solPrivateKey, social):
            switch event {
            case let .enterPhoneNumber(phone):
                if initialPhoneNumber == phone, didSend == true, let solPrivateKey = solPrivateKey {
                    return .enterOTP(
                        phone: phone,
                        solPrivateKey: solPrivateKey,
                        social: social,
                        attempt: resendCounter ?? .init(.zero())
                    )
                }

                let solPrivateKey = try NaclSign.KeyPair.keyPair().secretKey

                do {
                    return try await sendOTP(
                        phone: phone,
                        solPrivateKey: solPrivateKey,
                        social: social,
                        attempt: .init(.zero()),
                        provider: provider
                    )
                }
                catch let error as APIGatewayCooldownError {
                    return .block(until: Date() + error.cooldown, social: social, reason: .blockEnterPhoneNumber)
                }

            case .back:
                return .finish(result: .breakProcess)

            default:
                throw StateMachineError.invalidEvent
            }

        case let .enterOTP(phone, solPrivateKey, social, attempt):
            switch event {
            case let .enterOTP(otp):
                do {
                    let result = try await provider.apiGatewayClient.confirmRestoreWallet(
                        solanaPrivateKey: solPrivateKey,
                        phone: phone,
                        otpCode: otp,
                        timestampDevice: Date()
                    )

                    if let torusKey = social?.torusKey, let deviceShare = provider.deviceShare {
                        return try await restore(
                            with: torusKey,
                            customShare: result.encryptedShare,
                            encryptedMetadata: result.encryptedMetaData,
                            encryptedMnemonic: result.encryptedPayload,
                            deviceShare: deviceShare,
                            tKey: provider.tKeyFacade
                        )
                    } else if let deviceShare = provider.deviceShare {
                        do {
                            try await provider.tKeyFacade.initialize()
                            let finalResult = try await provider.tKeyFacade.signIn(
                                deviceShare: deviceShare,
                                customShare: result.encryptedShare,
                                encryptedMnemonic: result.encryptedPayload
                            )

                            let encryptedMetadata = try JSONDecoder()
                                .decode(Crypto.EncryptedMetadata.self, from: Data(result.encryptedMetaData.utf8))
                            let metadataRaw = try Crypto.decryptMetadata(
                                seedPhrase: finalResult.privateSOL,
                                encryptedMetadata: encryptedMetadata
                            )
                            let metadata = try JSONDecoder().decode(WalletMetaData.self, from: metadataRaw)

                            return .finish(
                                result: .successful(
                                    seedPhrase: finalResult.privateSOL,
                                    ethPublicKey: finalResult.reconstructedETH,
                                    metadata: metadata
                                )
                            )
                        } catch {
                            if provider.deviceShare != nil, (error as? TKeyFacadeError)?.code == 1009 {
                                return .notFoundDevice(result: result)
                            } else {
                                return .noMatch
                            }
                        }
                    } else {
                        return .finish(result: .requireSocialCustom(result: result))
                    }
                } catch let error as APIGatewayError {
                    switch error._code {
                    case -32700, -32600, -32601, -32602, -32603, -32052:
                        return .broken(code: error.rawValue)
                    default:
                        throw error
                    }
                } catch let error as APIGatewayCooldownError {
                    return .block(until: Date() + error.cooldown, social: social, reason: .blockEnterOTP)
                }

            case .resendOTP:
                do {
                    let state = try await sendOTP(
                        phone: phone,
                        solPrivateKey: solPrivateKey,
                        social: social,
                        attempt: attempt,
                        provider: provider
                    )
                    attempt.value = attempt.value.incremented()
                    return state
                }
                catch let error as APIGatewayCooldownError {
                    return .block(until: Date() + error.cooldown, social: social, reason: .blockResend)
                }

            case .back:
                return .enterPhone(
                    initialPhoneNumber: phone,
                    didSend: true,
                    resendCounter: attempt,
                    solPrivateKey: solPrivateKey,
                    social: social
                )

            default:
                throw StateMachineError.invalidEvent
            }

        case .otpNotDeliveredTrySocial:
            switch event {
            case .back:
                return .enterPhone(
                    initialPhoneNumber: nil,
                    didSend: false,
                    resendCounter: nil,
                    solPrivateKey: nil,
                    social: nil
                )
            case let .requireSocial(provider):
                return .finish(result: .requireSocialDevice(provider: provider, result: nil))
            case .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case .otpNotDelivered, .broken, .noMatch:
            switch event {
            case .back, .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .tryAnother(_, trySocial):
            switch event {
            case .enterPhone:
                return .enterPhone(
                    initialPhoneNumber: nil,
                    didSend: false,
                    resendCounter: nil,
                    solPrivateKey: nil,
                    social: nil
                )
            case let .requireSocial(provider):
                if trySocial {
                    return .finish(result: .requireSocialDevice(provider: provider, result: nil))
                } else {
                    throw StateMachineError.invalidEvent
                }
            case .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .block(until, _, _):
            switch event {
            case .start:
                return .finish(result: .start)
            case .enterPhone:
                guard Date() > until else { throw StateMachineError.invalidEvent }
                return .enterPhone(
                    initialPhoneNumber: nil,
                    didSend: false,
                    resendCounter: nil,
                    solPrivateKey: nil,
                    social: nil
                )
            default:
                throw StateMachineError.invalidEvent
            }

        case let .notFoundDevice(result):
            switch event {
            case .enterPhone:
                return .enterPhone(
                    initialPhoneNumber: nil,
                    didSend: false,
                    resendCounter: nil,
                    solPrivateKey: nil,
                    social: nil
                )
            case let .requireSocial(provider):
                return .finish(result: .requireSocialDevice(provider: provider, result: result))
            case .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case .finish:
            switch event {
            default:
                throw StateMachineError.invalidEvent
            }
        }
    }

    private func restore(
        with torusKey: TorusKey,
        customShare: String,
        encryptedMetadata: String,
        encryptedMnemonic: String,
        deviceShare: String,
        tKey: TKeyFacade
    ) async throws -> RestoreCustomState {
        do {
            try await tKey.initialize()
            let finalResult = try await tKey.signIn(
                torusKey: torusKey,
                customShare: customShare,
                encryptedMnemonic: encryptedMnemonic
            )

            let metadata = try WalletMetaData.decrypt(seedPhrase: finalResult.privateSOL, data: encryptedMetadata)

            return .finish(
                result: .successful(
                    seedPhrase: finalResult.privateSOL,
                    ethPublicKey: finalResult.reconstructedETH,
                    metadata: metadata
                )
            )
        } catch {
            do {
                try await tKey.initialize()
                let finalResult = try await tKey.signIn(
                    deviceShare: deviceShare,
                    customShare: customShare,
                    encryptedMnemonic: encryptedMnemonic
                )

                let metadata = try? WalletMetaData.decrypt(seedPhrase: finalResult.privateSOL, data: encryptedMetadata)

                return .finish(
                    result: .successful(
                        seedPhrase: finalResult.privateSOL,
                        ethPublicKey: finalResult.reconstructedETH,
                        metadata: metadata
                    )
                )
            } catch {
                return .noMatch
            }
        }
    }

    private func sendOTP(
        phone: String,
        solPrivateKey: Data,
        social: RestoreSocialData?,
        attempt: Wrapper<ResendCounter>,
        provider: RestoreCustomContainer
    ) async throws -> RestoreCustomState {
        do {
            try await provider.apiGatewayClient.restoreWallet(
                solPrivateKey: solPrivateKey,
                phone: phone,
                channel: .sms,
                timestampDevice: Date()
            )
            return .enterOTP(phone: phone, solPrivateKey: solPrivateKey, social: social, attempt: attempt)
        } catch let error as APIGatewayError {
            switch error._code {
            case -32058, -32700, -32600, -32601, -32602, -32603, -32052:
                return .broken(code: error.rawValue)
            case -32060:
                return .tryAnother(wrongNumber: phone, trySocial: provider.deviceShare != nil)
            case -32054:
                if provider.deviceShare != nil {
                    return .otpNotDeliveredTrySocial(phone: phone, code: error.rawValue)
                } else {
                    return .otpNotDelivered(phone: phone, code: error.rawValue)
                }

            default:
                throw error
            }
        }
    }
}

extension RestoreCustomState: Step, Continuable {
    public var continuable: Bool { true }

    public var step: Float {
        switch self {
        case .enterPhone:
            return 1
        case .enterOTP:
            return 2
        case .otpNotDeliveredTrySocial:
            return 3
        case .otpNotDelivered:
            return 4
        case .noMatch:
            return 5
        case .notFoundDevice:
            return 6
        case .broken:
            return 7
        case .tryAnother:
            return 8
        case .block:
            return 9
        case .finish:
            return 10
        }
    }
}
