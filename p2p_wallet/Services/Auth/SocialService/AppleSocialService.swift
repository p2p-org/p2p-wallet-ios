//
//  AppleSocialService.swift
//  p2p_wallet
//
//  Created by Ivan on 25.07.2022.
//

import AuthenticationServices
import Resolver

final class AppleSocialService: NSObject, SocialService {
    private typealias AuthContinuation = CheckedContinuation<SocialAuthResponse, Error>
    private var authContinuation: AuthContinuation?

    @Injected private var jwtValidator: JWTTokenValidator

    func auth() async throws -> SocialAuthResponse {
        try await withCheckedThrowingContinuation { continuation in

            authContinuation = continuation

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            request.requestedScopes = [.email]
            authorizationController.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSocialService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        window() ?? UIWindow()
    }

    private func window() -> UIWindow? {
        UIApplication.shared.connectedScenes.filter {
            $0.activationState == .foregroundActive
        }
        .first(where: { $0 is UIWindowScene })
        .flatMap { $0 as? UIWindowScene }?.windows
        .first(where: \.isKeyWindow)
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSocialService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authContinuation?.resume(with: .failure(SocialServiceError.unknown))
            return
        }
        guard
            let tokenIDRaw = appleIDCredential.identityToken,
            let tokenID = String(data: tokenIDRaw, encoding: .utf8)
        else {
            authContinuation?.resume(with: .failure(SocialServiceError.tokenIDIsNil))
            return
        }

        let jwtModel = jwtValidator.decode(tokenID: tokenID)

        authContinuation?.resume(with: .success(
            SocialAuthResponse(
                accessToken: appleIDCredential.user,
                tokenID: tokenID,
                email: jwtModel?.email ?? "?"
            )
        ))
        authContinuation = nil
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        var retError = error
        if let authError = (error as? ASAuthorizationError), case ASAuthorizationError.canceled = authError {
            retError = SocialServiceError.cancelled
        }
        authContinuation?.resume(with: .failure(retError))
        authContinuation = nil
    }
}
