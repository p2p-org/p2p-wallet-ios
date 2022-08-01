//
//  AuthService.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import Foundation

protocol AuthService {
    func socialSignIn(_ socialType: SocialType) async throws -> SocialAuthResponse
    func phoneSignIn(_ phoneNumber: String) async throws
}
