// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import TweetNacl

public enum RestoreWalletFlowResult: Codable, Equatable {
    case successful(RestoreWalletData)
    case breakProcess
}

public typealias RestoreWalletStateMachine = StateMachine<RestoreWalletState>

public struct RestoreWalletFlowContainer {
    let tKeyFacade: TKeyFacade
    let deviceShare: String?
    let authService: SocialAuthService
    let apiGatewayClient: APIGatewayClient
    let icloudAccountProvider: ICloudAccountProvider

    public init(
        tKeyFacade: TKeyFacade,
        deviceShare: String?,
        authService: SocialAuthService,
        apiGatewayClient: APIGatewayClient,
        icloudAccountProvider: ICloudAccountProvider
    ) {
        self.tKeyFacade = tKeyFacade
        self.deviceShare = deviceShare
        self.authService = authService
        self.apiGatewayClient = apiGatewayClient
        self.icloudAccountProvider = icloudAccountProvider
    }
}

public enum RestoreWalletState: Codable, State, Equatable {
    public typealias Event = RestoreWalletEvent
    public typealias Provider = RestoreWalletFlowContainer
    public static var initialState: RestoreWalletState = .restore

    case restore
    case restoreICloud(RestoreICloudState)
    case restoreSeed(RestoreSeedState)
    case restoreSocial(RestoreSocialState, option: RestoreSocialContainer.Option)
    case restoreCustom(RestoreCustomState)

    case securitySetup(
        wallet: OnboardingWallet,
        ethPublicKey: String?,
        metadata: WalletMetaData?,
        SecuritySetupState
    )

    case finished(RestoreWalletFlowResult)

    public func accept(
        currentState: RestoreWalletState,
        event: RestoreWalletEvent,
        provider: Provider
    ) async throws -> RestoreWalletState {
        switch currentState {
        case .restore:

            switch event {
            case let .restoreICloud(event):
                switch event {
                case let .restoreRawWallet(name, phrase, derivablePath):
                    let event = RestoreICloudEvent.restoreRawWallet(
                        name: name,
                        phrase: phrase,
                        derivablePath: derivablePath
                    )
                    let innerState = RestoreICloudState.signIn
                    let nextInnerState = try await innerState <- (
                        event,
                        .init(icloudAccountProvider: provider.icloudAccountProvider)
                    )

                    if case let .finish(result) = nextInnerState {
                        return handleRestoreICloud(result: result)
                    } else {
                        return .restoreICloud(nextInnerState)
                    }

                case .signIn:
                    let nextInnerState = try await RestoreICloudState.signIn <- (
                        RestoreICloudEvent.signIn,
                        .init(icloudAccountProvider: provider.icloudAccountProvider)
                    )

                    if case let .chooseWallet(accounts) = nextInnerState {
                        return .restoreICloud(.chooseWallet(accounts: accounts))
                    } else {
                        return .restoreICloud(.signIn)
                    }
                default:
                    throw StateMachineError.invalidEvent
                }

            case let .restoreSeed(event):
                switch event {
                case .signInWithSeed:
                    return .restoreSeed(.signInSeed)
                default:
                    throw StateMachineError.invalidEvent
                }

            case let .restoreCustom(event):
                switch event {
                case .enterPhone:
                    return .restoreCustom(
                        .enterPhone(
                            initialPhoneNumber: nil,
                            didSend: false,
                            resendCounter: nil,
                            solPrivateKey: nil,
                            social: nil
                        )
                    )
                default:
                    throw StateMachineError.invalidEvent
                }

            case let .restoreSocial(event):
                switch event {
                case let .signInDevice(socialProvider):
                    return try await handleSignInDeviceEvent(
                        provider: provider,
                        socialProvider: socialProvider,
                        customResult: nil,
                        option: .device
                    )

                default:
                    throw StateMachineError.invalidEvent
                }

            case .back:
                return .finished(.breakProcess)

            case .start:
                return .finished(.breakProcess)

            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoreSocial(innerState, option):
            switch event {
            case let .restoreSocial(event):
                let nextInnerState = try await innerState <- (
                    event,
                    .init(option: option, tKeyFacade: provider.tKeyFacade, authService: provider.authService)
                )

                if case let .finish(result) = nextInnerState {
                    return try await handleRestoreSocial(result: result)
                } else {
                    return .restoreSocial(nextInnerState, option: option)
                }
            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoreCustom(innerState):
            switch event {
            case let .restoreCustom(event):
                let nextInnerState = try await innerState <- (
                    event,
                    .init(
                        tKeyFacade: provider.tKeyFacade,
                        apiGatewayClient: provider.apiGatewayClient,
                        authService: provider.authService,
                        deviceShare: provider.deviceShare
                    )
                )

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .successful(seedPhrase, ethPublicKey, metadata):
                        return .securitySetup(
                            wallet: OnboardingWallet(seedPhrase: seedPhrase),
                            ethPublicKey: ethPublicKey,
                            metadata: metadata,
                            SecuritySetupState.initialState
                        )
                    case let .requireSocialCustom(result):
                        return .restoreSocial(.social(result: result), option: .custom)
                    case let .requireSocialDevice(socialProvider, customResult):
                        return try await handleSignInDeviceEvent(
                            provider: provider,
                            socialProvider: socialProvider,
                            customResult: customResult,
                            option: .customDevice
                        )
                    case .start:
                        return .finished(.breakProcess)
                    case .breakProcess:
                        return .restore
                    }
                } else {
                    return .restoreCustom(nextInnerState)
                }

            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoreSeed(innerState):
            switch event {
            case let .restoreSeed(event):
                let nextInnerState = try await innerState <- (event, .init())

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .successful(phrase, derivablePath):
                        return .securitySetup(
                            wallet: OnboardingWallet(
                                seedPhrase: phrase.joined(separator: " "),
                                derivablePath: derivablePath
                            ),
                            ethPublicKey: nil,
                            metadata: nil,
                            SecuritySetupState.initialState
                        )
                    case .back:
                        return .restore
                    }
                } else {
                    return .restoreSeed(nextInnerState)
                }

            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoreICloud(innerState):
            switch event {
            case let .restoreICloud(event):
                let nextInnerState = try await innerState <- (
                    event,
                    .init(icloudAccountProvider: provider.icloudAccountProvider)
                )

                if case let .finish(result) = nextInnerState {
                    return handleRestoreICloud(result: result)
                } else {
                    return .restoreICloud(nextInnerState)
                }

            default:
                throw StateMachineError.invalidEvent
            }

        case let .securitySetup(wallet, ethPublicKey, metadata, innerState):
            switch event {
            case let .securitySetup(event):
                let nextInnerState = try await innerState <- (event, .init())

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .success(securityData):
                        return .finished(
                            .successful(
                                RestoreWalletData(
                                    ethAddress: ethPublicKey,
                                    wallet: wallet,
                                    security: securityData,
                                    metadata: metadata
                                )
                            )
                        )
                    }
                } else {
                    return .securitySetup(
                        wallet: wallet,
                        ethPublicKey: ethPublicKey,
                        metadata: metadata,
                        nextInnerState
                    )
                }
            default:
                throw StateMachineError.invalidEvent
            }

        case .finished:
            throw StateMachineError.invalidEvent
        }
    }

    private func handleRestoreSocial(result: RestoreSocialResult) async throws -> RestoreWalletState {
        switch result {
        case let .successful(seedPhrase, ethPublicKey):
            return .securitySetup(
                wallet: OnboardingWallet(seedPhrase: seedPhrase),
                ethPublicKey: ethPublicKey,
                metadata: nil,
                SecuritySetupState.initialState
            )
        case .start:
            return .finished(.breakProcess)
        case let .requireCustom(data):
            return .restoreCustom(
                .enterPhone(
                    initialPhoneNumber: nil,
                    didSend: false,
                    resendCounter: nil,
                    solPrivateKey: nil,
                    social: data
                )
            )
        }
    }

    private func handleSignInDeviceEvent(
        provider: RestoreWalletFlowContainer,
        socialProvider: SocialProvider,
        customResult: APIGatewayRestoreWalletResult?,
        option: RestoreSocialContainer.Option
    ) async throws -> RestoreWalletState {
        guard let deviceShare = provider.deviceShare else { throw StateMachineError.invalidEvent }
        let event = RestoreSocialEvent.signInDevice(socialProvider: socialProvider)
        let innerState = RestoreSocialState.signIn(deviceShare: deviceShare, customResult: customResult)
        let nextInnerState = try await innerState <- (
            event,
            .init(
                option: option,
                tKeyFacade: provider.tKeyFacade,
                authService: provider.authService
            )
        )

        if case let .finish(result) = nextInnerState {
            return try await handleRestoreSocial(result: result)
        } else {
            return .restoreSocial(nextInnerState, option: option)
        }
    }

    private func handleRestoreICloud(result: RestoreICloudResult) -> RestoreWalletState {
        switch result {
        case let .successful(phrase, derivablePath):
            return .securitySetup(
                wallet: OnboardingWallet(
                    seedPhrase: phrase,
                    derivablePath: derivablePath
                ),
                ethPublicKey: nil,
                metadata: nil,
                SecuritySetupState.initialState
            )
        case .back:
            return .restore
        }
    }
}

public enum RestoreWalletEvent {
    case back
    case start

    case restoreSocial(RestoreSocialEvent)
    case restoreCustom(RestoreCustomEvent)
    case restoreSeed(RestoreSeedEvent)
    case restoreICloud(RestoreICloudEvent)
    case securitySetup(SecuritySetupEvent)
}

extension RestoreWalletState: Step, Continuable {
    public var continuable: Bool {
        switch self {
        case .restore:
            return false
        case let .restoreSeed(restoreSeedState):
            return restoreSeedState.continuable
        case let .restoreSocial(restoreSocialState, _):
            return restoreSocialState.continuable
        case let .restoreCustom(restoreCustomState):
            return restoreCustomState.continuable
        case let .restoreICloud(restoreICloudState):
            return restoreICloudState.continuable
        case let .securitySetup(_, _, _, securitySetupState):
            return securitySetupState.continuable
        case .finished:
            return false
        }
    }

    public var step: Float {
        switch self {
        case .restore:
            return 1 * 100
        case let .restoreICloud(restoreICloudState):
            return 2 * 100 + restoreICloudState.step
        case let .restoreSeed(restoreSeedState):
            return 3 * 100 + restoreSeedState.step

        // Social before custom
        case let .restoreSocial(.signIn(deviceShare, customResult), option: _):
            return 4 * 100 + RestoreSocialState.signIn(deviceShare: deviceShare, customResult: customResult).step
        case let .restoreSocial(.notFoundDevice(data, deviceShare, customResult), .device):
            return 4 * 100 + RestoreSocialState.notFoundDevice(
                data: data,
                deviceShare: deviceShare,
                customResult: customResult
            ).step
        case let .restoreSocial(.notFoundSocial(data, deviceShare, customResult), option: _):
            return 4 * 100 + RestoreSocialState.notFoundSocial(
                data: data,
                deviceShare: deviceShare,
                customResult: customResult
            ).step
        case let .restoreSocial(.signInProgress(tokenID, email, deviceShare, customResult, backState), option: .device):
            return 4 * 100 + RestoreSocialState.signInProgress(tokenID: tokenID, email: email, deviceShare: deviceShare, customResult: customResult, backState: backState).step

        // Custom
        case let .restoreCustom(restoreCustomState):
            return 5 * 100 + restoreCustomState.step

        // Social after custom
        case let .restoreSocial(.social(result), option: _):
            return 6 * 100 + RestoreSocialState.social(result: result).step
        case let .restoreSocial(.notFoundCustom(result, email), option: _):
            return 6 * 100 + RestoreSocialState.notFoundCustom(result: result, email: email).step
        case let .restoreSocial(.finish(finishResult), option: _):
            return 6 * 100 + RestoreSocialState.finish(finishResult).step
        case let .restoreSocial(.notFoundDevice(data, deviceShare, customResult), .custom):
            return 6 * 100 + RestoreSocialState.notFoundDevice(
                data: data,
                deviceShare: deviceShare,
                customResult: customResult
            ).step
        case let .restoreSocial(.notFoundDevice(data, deviceShare, customResult), .customDevice):
            return 6 * 100 + RestoreSocialState.notFoundDevice(
                data: data,
                deviceShare: deviceShare,
                customResult: customResult
            ).step
        case let .restoreSocial(.signInProgress(tokenID, email, deviceShare, customResult, backState), option: .custom):
            return 6 * 100 + RestoreSocialState.signInProgress(tokenID: tokenID, email: email, deviceShare: deviceShare, customResult: customResult, backState: backState).step
        case let .restoreSocial(.signInProgress(tokenID, email, deviceShare, customResult, backState), option: .customDevice):
            return 6 * 100 + RestoreSocialState.signInProgress(tokenID: tokenID, email: email, deviceShare: deviceShare, customResult: customResult, backState: backState).step

        case let .securitySetup(_, _, _, securitySetupState):
            return 7 * 100 + securitySetupState.step
        case .finished:
            return 8 * 100
        }
    }
}
