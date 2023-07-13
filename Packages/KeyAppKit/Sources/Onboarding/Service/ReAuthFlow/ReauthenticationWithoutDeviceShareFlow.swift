import Foundation
import KeyAppKitCore

public struct ReAuthWithoutDeviceShareProvider {
    let apiGateway: APIGatewayClient
    let facade: TKeyFacade
    let socialAuthService: SocialAuthService
    let walletMetadata: WalletMetaData
    let errorObserver: ErrorObserver

    let expectedEmail: String

    public init(
        apiGateway: APIGatewayClient,
        facade: TKeyFacade,
        socialAuthService: SocialAuthService,
        walletMetadata: WalletMetaData,
        errorObserver: ErrorObserver,
        expectedEmail: String
    ) {
        self.apiGateway = apiGateway
        self.facade = facade
        self.socialAuthService = socialAuthService
        self.walletMetadata = walletMetadata
        self.errorObserver = errorObserver
        self.expectedEmail = expectedEmail
    }
}

public enum ReAuthWithoutDeviceShareEvent: Equatable {
    case customShareEvent(ReAuthCustomShareEvent)
    case socialShareEvent(ReAuthSocialShareEvent)
}

public enum ReAuthWithoutDeviceShareState: State, Equatable {
    public typealias Event = ReAuthWithoutDeviceShareEvent
    public typealias Provider = ReAuthWithoutDeviceShareProvider

    public static var initialState: Self = .customShare(.initialState)
    static let realtimeErrorConfig: ErrorObserverConfig = .init(domain: "Web3Auth ReAuth", flags: .realtimeAlert)

    case customShare(ReAuthCustomShareState)
    case socialShare(ReAuthSocialShareState, ReAuthenticationCustomShareResult)

    case finish
    case cancel

    public func accept(
        currentState: ReAuthWithoutDeviceShareState,
        event: ReAuthWithoutDeviceShareEvent,
        provider: ReAuthWithoutDeviceShareProvider
    ) async throws -> Self {
        switch currentState {
        case let .customShare(innerState):
            guard case let .customShareEvent(innerEvent) = event else {
                throw StateMachineError.invalidEvent
            }

            let nextInnerState = try await innerState <- (
                innerEvent,
                .init(
                    apiGateway: provider.apiGateway,
                    errorObserver: provider.errorObserver
                )
            )

            switch nextInnerState {
            case let .finish(result):
                return .socialShare(
                    .signIn(socialProvider: SocialProvider(rawValue: provider.walletMetadata.authProvider) ?? .google),
                    result
                )

            case .cancel:
                return .cancel

            default:
                return .customShare(nextInnerState)
            }

        case let .socialShare(innerState, customShareResult):
            guard case let .socialShareEvent(innerEvent) = event else {
                throw StateMachineError.invalidEvent
            }

            let nextInnerState = try await innerState <- (
                innerEvent,
                .init(
                    tkeyFacade: provider.facade,
                    socialAuthService: provider.socialAuthService,
                    errorObserver: provider.errorObserver,
                    expectedEmail: provider.expectedEmail
                )
            )

            switch nextInnerState {
            case let .finish(result):
                do {
                    _ = try await provider.facade.signIn(
                        torusKey: result.torusKey,
                        customShare: customShareResult.customShare,
                        encryptedMnemonic: customShareResult.encryptedMnemonic
                    )
                } catch {
                    throw provider.errorObserver.intercept(error, config: Self.realtimeErrorConfig)
                }

                return .finish

            case .cancel:
                return .cancel

            default:
                return .socialShare(nextInnerState, customShareResult)
            }

        case .finish:
            return currentState

        case .cancel:
            return currentState
        }
    }
}

extension ReAuthWithoutDeviceShareState: Step {
    public var step: Float {
        switch self {
        case let .customShare(innerState):
            return 1 * 100 + innerState.step
        case let .socialShare(innerState, _):
            return 2 * 100 + innerState.step
        default:
            return 0
        }
    }
}
