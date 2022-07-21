//
//  AuthServiceImpl.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import Foundation
import KeychainSwift

final class AuthServiceImpl: AuthService {
    private let keychain = KeychainSwift()

    private var keySol: String? {
        get {
            keychain.get("keySol")
        }
        set {
            if let newValue = newValue {
                keychain.set(newValue, forKey: "keySol")
            } else {
                keychain.delete("keySol")
            }
        }
    }

    private var keyEthereum: String? {
        get {
            keychain.get("keyEthereum")
        }
        set {
            if let newValue = newValue {
                keychain.set(newValue, forKey: "keyEthereum")
            } else {
                keychain.delete("keyEthereum")
            }
        }
    }

    private var deviceShare: String? {
        get {
            keychain.get("deviceShare")
        }
        set {
            if let newValue = newValue {
                keychain.set(newValue, forKey: "deviceShare")
            } else {
                keychain.delete("deviceShare")
            }
        }
    }

    func auth(with userCredentials: AuthUserCredentials) async throws {
        switch userCredentials {
        case .phone:
            break
        case let .social(type):
            return try await socialLogin(type: type)
        }
    }

    private func socialLogin(type _: SocialType) async throws {
        throw SocialServiceError.unknown
//        guard let service = type.authObject() else { throw SocialServiceError.unknown }
//        return try await service.auth()
    }
}
