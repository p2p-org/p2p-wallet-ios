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

    @MainActor
    func auth() async throws -> SocialAuthResponse {
        guard let rootViewController = topMostController() else {
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
                    guard let tokenID = user.authentication.idToken else {
                        return continuation.resume(with: .failure(SocialServiceError.tokenIDIsNil))
                    }

                    continuation.resume(with: .success(SocialAuthResponse(
                        accessToken: user.authentication.accessToken,
                        tokenID: tokenID,
                        email: user.profile?.email ?? "?"
                    )))
                }
            }
        }
    }

    // Get top presented view controller
    private func topMostController() -> UIViewController? {
        UIApplication.shared.connectedScenes.filter {
            $0.activationState == .foregroundActive
        }.first(where: { $0 is UIWindowScene })
            .flatMap { $0 as? UIWindowScene }?.windows
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostViewController()
    }
}

private extension UIViewController {
    func topMostViewController() -> UIViewController {
        if presentedViewController == nil {
            return self
        }

        if let navigation = presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }

        if let tab = presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }

        return presentedViewController!.topMostViewController()
    }
}

// MARK: - AppUrlHandler

extension GoogleSocialService: AppUrlHandler {
    func handle(url: URL, options _: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
