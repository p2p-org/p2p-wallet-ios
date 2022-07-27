//
//  SocialService.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import Foundation

protocol SocialService: AnyObject {
    func auth() async throws -> SocialAuthResponse
}

extension SocialType {
    func authObject() -> SocialService? {
        switch self {
        case .apple:
            return AppleSocialService()
        case .google:
            return GoogleSocialService(
                clientId: Environment.current == .release
                    ? String.secretConfig("GOOGLE_SIGN_IN_ID_RELEASE")!
                    : String.secretConfig("GOOGLE_SIGN_IN_ID_DEBUG")!
            )
        }
    }
}
