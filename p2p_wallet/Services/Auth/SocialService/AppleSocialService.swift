//
//  AppleSocialService.swift
//  p2p_wallet
//
//  Created by Ivan on 25.07.2022.
//

import AuthenticationServices

final class AppleSocialService: NSObject, SocialService {
    private typealias AuthContinuation = CheckedContinuation<SocialAuthResponse, Error>
    private var authContinuation: AuthContinuation?

    func auth() async throws -> SocialAuthResponse {
        try await withCheckedThrowingContinuation { continuation in

            authContinuation = continuation

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            request.requestedScopes = [.email]
            authorizationController.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSocialService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        authContinuation?.resume(with: .success(SocialAuthResponse(accessToken: appleIDCredential.user)))
        authContinuation = nil
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        authContinuation?.resume(with: .failure(error))
        authContinuation = nil
    }
}
