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
            return nil
        case .google:
            return GoogleSocialService(
                clientId: Environment.current == .release
                    ? "553127941597-0p8uojdah9afr4ugfdqm47fvlskp3ejk.apps.googleusercontent.com"
                    : "553127941597-nme6s6lf62oubsqut4dmlk1v2p4p0om0.apps.googleusercontent.com"
            )
        }
    }
}
