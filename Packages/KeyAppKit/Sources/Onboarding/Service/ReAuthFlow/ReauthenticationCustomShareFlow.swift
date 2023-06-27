//
//  File.swift
//
//
//  Created by Giang Long Tran on 15/06/2023.
//

import Foundation

public struct ReAuthCustomShareProvider {
    let apiGateway: APIGatewayClient
}

public enum ReAuthCustomShareEvent: Codable, Equatable {
    case start
    case resendOTP
    case enterOTP(String)
    case blockValidate
    case back
}

public struct ReAuthenticationCustomShareResult: Equatable {
    let customShare: String
    let encryptedMnemonic: String

    public init(customShare: String, encryptedMnemonic: String) {
        self.customShare = customShare
        self.encryptedMnemonic = encryptedMnemonic
    }
}

public enum ReAuthCustomShareState: State, Equatable {
    public typealias Event = ReAuthCustomShareEvent
    public typealias Provider = ReAuthCustomShareProvider

    public static var initialState: Self = .otpInput(
        phoneNumber: "",
        solPrivateKey: Data(),
        resendCounter: .init(.zero())
    )

    case otpInput(
        phoneNumber: String,
        solPrivateKey: Data,
        resendCounter: Wrapper<ResendCounter>
    )
    case block(until: Date, phoneNumber: String, solPrivateKey: Data)

    case finish(result: ReAuthenticationCustomShareResult)

    case cancel

    public func accept(currentState: Self, event: Event, provider: Provider) async throws -> Self {
        switch currentState {
        case .otpInput:
            return try await handleEventForOtpInputState(
                state: currentState,
                event: event,
                provider: provider
            )

        case .finish:
            return currentState

        case .block:
            return try await handleEventForBlockState(
                state: currentState,
                event: event,
                provider: provider
            )

        case .cancel:
            return currentState
        }
    }

    func handleEventForOtpInputState(
        state: Self,
        event: Event,
        provider: Provider
    ) async throws -> Self {
        guard case let .otpInput(phoneNumber, solPrivateKey, resendCounter) = state else {
            throw StateMachineError.invalidState
        }

        switch event {
        case .start:
            try await provider.apiGateway.restoreWallet(
                solPrivateKey: solPrivateKey,
                phone: phoneNumber,
                channel: .sms,
                timestampDevice: Date()
            )

            return self

        case let .enterOTP(code):
            let result = try await provider.apiGateway.confirmRestoreWallet(
                solanaPrivateKey: solPrivateKey,
                phone: phoneNumber,
                otpCode: code,
                timestampDevice: Date()
            )

            return .finish(
                result: ReAuthenticationCustomShareResult(
                    customShare: result.encryptedShare,
                    encryptedMnemonic: result.encryptedPayload
                )
            )

        case .resendOTP:
            try await provider.apiGateway.restoreWallet(
                solPrivateKey: solPrivateKey,
                phone: phoneNumber,
                channel: .sms,
                timestampDevice: Date()
            )

            resendCounter.value = resendCounter.value.incremented()

            return self

        case .back:
            return .cancel

        default:
            return self
        }
    }

    func handleEventForBlockState(
        state: Self,
        event: Event,
        provider _: Provider
    ) async throws -> Self {
        guard case let .block(until, phoneNumber, solPrivateKey) = state else {
            throw StateMachineError.invalidState
        }

        switch event {
        case .blockValidate:
            guard Date() > until else { throw StateMachineError.invalidEvent }
            return .otpInput(
                phoneNumber: phoneNumber,
                solPrivateKey: solPrivateKey,
                resendCounter: .init(.zero())
            )
        default:
            return self
        }
    }
}

extension ReAuthCustomShareState: Step {
    public var step: Float {
        switch self {
        case .otpInput:
            return 1
        case .block:
            return 2
        default:
            return 0
        }
    }
}