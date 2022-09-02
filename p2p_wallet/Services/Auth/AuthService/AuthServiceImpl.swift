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

        #if DEBUG
            if available(.simulatedSocialError) {
                switch Int.random(in: 0 ... 1) {
                case 0: throw SocialServiceError.tokenIDIsNil
                case 1: throw SocialServiceError.unknown
                default: break
                }
            }
        #endif

        return try await service.auth()
    }

    func phoneSignIn(_: String) async throws {}
}
