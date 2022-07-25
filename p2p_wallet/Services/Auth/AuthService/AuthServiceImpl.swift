//
//  AuthServiceImpl.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import Foundation
import KeychainSwift

final class AuthServiceImpl: AuthService {
    func auth(with userCredentials: AuthUserCredentials) async throws {
        switch userCredentials {
        case .phone:
            break
        case let .social(type):
            try await socialLogin(type: type)
        }
    }

    private func socialLogin(type: SocialType) async throws {
        guard let service = type.authObject() else { throw SocialServiceError.unknown }
        try await service.auth()
    }
}
