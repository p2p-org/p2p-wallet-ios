//
//  GoogleSocialService.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import GoogleSignIn
import SwiftNotificationCenter
import UIKit

final class GoogleSocialService: NSObject, SocialService {
    private let signInConfig: GIDConfiguration

    init(clientId: String) {
        signInConfig = GIDConfiguration(clientID: clientId)
        super.init()
        Broadcaster.register(AppUrlHandler.self, observer: self)
    }

    func auth() async throws -> SocialAuthResponse {
        guard let rootViewController = await UIApplication.shared.rootViewController() else {
            throw SocialServiceError.unknown
        }

        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(
                with: signInConfig,
                presenting: rootViewController
            ) { user, error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                } else {
                    guard let user = user else {
                        return continuation.resume(with: .failure(SocialServiceError.unknown))
                    }
                    continuation.resume(with: .success(SocialAuthResponse(
                        accessToken: user.authentication.accessToken
                    )))
                }
            }
        }
    }
}

// MARK: - AppUrlHandler

extension GoogleSocialService: AppUrlHandler {
    func handle(url: URL, options _: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
