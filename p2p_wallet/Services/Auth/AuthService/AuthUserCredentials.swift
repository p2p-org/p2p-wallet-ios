//
//  AuthUserCredentials.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import Foundation

enum AuthUserCredentials {
    case phone(_ phone: String)
    case social(_ type: SocialType)
}
