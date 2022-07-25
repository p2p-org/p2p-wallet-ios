//
//  AuthService.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import Foundation

protocol AuthService {
    func auth(with userCredentials: AuthUserCredentials) async throws
}
