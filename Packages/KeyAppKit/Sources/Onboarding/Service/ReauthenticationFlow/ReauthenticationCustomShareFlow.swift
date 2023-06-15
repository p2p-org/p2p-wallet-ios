//
//  File.swift
//
//
//  Created by Giang Long Tran on 15/06/2023.
//

import Foundation

public struct ReauthenticationCustomShareProvider {
    let apiGateway: APIGatewayClient
}

public enum ReauthenticationCustomShareEvent: Codable, Equatable {
    case start
    case resendOTP
    case enterOTP(String)
}

public struct ReauthenticationCustomShareResult: Equatable {
    let customShare: String
    let encryptedMnemonic: String
}

public enum ReauthenticationCustomShareState: State, Equatable {
    public typealias Event = ReauthenticationCustomShareEvent
    public typealias Provider = ReauthenticationCustomShareProvider

    public static var initialState: Self = .otpInput(
        phoneNumber: "",
        solPrivateKey: Data()
    )

    case otpInput(
        phoneNumber: String,
        solPrivateKey: Data
    )
    case finish(result: ReauthenticationCustomShareResult)

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
        }
    }

    func handleEventForOtpInputState(
        state: Self,
        event: Event,
        provider: Provider
    ) async throws -> Self {
        guard case let .otpInput(phoneNumber, solPrivateKey) = state else {
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
                result: ReauthenticationCustomShareResult(
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

            return self
        }
    }
}
