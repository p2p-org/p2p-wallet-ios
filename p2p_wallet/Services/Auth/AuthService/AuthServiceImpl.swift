//
//  AuthServiceImpl.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import Foundation
import KeychainSwift

final class AuthServiceImpl: AuthService {
    func socialSignIn(_ type: SocialType) async throws -> SocialAuthResponse {
        guard let service = type.authObject() else { throw SocialServiceError.invalidSocialType }
        return try await service.auth()
    }

    func phoneSignIn(_: String) async throws {}
}
