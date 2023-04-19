// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public enum RestoreICloudResult: Codable, Equatable {
    case successful(phrase: String, derivablePath: DerivablePath)
    case back
}

public enum RestoreICloudEvent {
    case back
    case signIn
    case restoreRawWallet(name: String?, phrase: String, derivablePath: DerivablePath)
    case restoreWallet(account: ICloudAccount)
}

public struct RestoreICloudContainer {
    let icloudAccountProvider: ICloudAccountProvider
}

public enum RestoreICloudState: Codable, State, Equatable {
    public typealias Event = RestoreICloudEvent
    public typealias Provider = RestoreICloudContainer

    case signIn
    case chooseWallet(accounts: [ICloudAccount])
    case finish(result: RestoreICloudResult)

    public static var initialState: RestoreICloudState = .signIn

    public func accept(
        currentState: RestoreICloudState,
        event: RestoreICloudEvent,
        provider: RestoreICloudContainer
    ) async throws -> RestoreICloudState {
        switch currentState {
        case .signIn:
            switch event {
            case .signIn:
                let rawAccounts = try await provider.icloudAccountProvider.getAll()
                var accounts: [ICloudAccount] = []
                for rawAccount in rawAccounts {
                    accounts
                        .append(try await .init(
                            name: rawAccount.name,
                            phrase: rawAccount.phrase,
                            derivablePath: rawAccount.derivablePath
                        ))
                }
                return .chooseWallet(accounts: accounts)

            case let .restoreRawWallet(name, phrase, derivablePath):
                return .finish(result: .successful(phrase: phrase, derivablePath: derivablePath))

            default:
                throw StateMachineError.invalidEvent
            }

        case let .chooseWallet(accounts):
            switch event {
            case let .restoreWallet(icloudAccount):
                return .finish(result: .successful(
                    phrase: icloudAccount.phrase,
                    derivablePath: icloudAccount.derivablePath
                ))
            case .back:
                return .finish(result: .back)
            default:
                throw StateMachineError.invalidEvent
            }
        case let .finish(result):
            throw StateMachineError.invalidEvent
        }
    }

    private func account(from icloudAccount: ICloudAccount) async throws -> Account {
        let account = try await Account(
            phrase: icloudAccount.phrase.components(separatedBy: " "),
            network: .mainnetBeta,
            derivablePath: icloudAccount.derivablePath
        )
        return account
    }
}

extension RestoreICloudState: Step, Continuable {
    public var continuable: Bool { true }

    public var step: Float {
        switch self {
        case .signIn:
            return 1
        case .chooseWallet:
            return 2
        case .finish:
            return 3
        }
    }
}
