//
//  TokensRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation

protocol TokensRepository {
    var supportedTokens: [SolanaSDK.Token] {get}
}

extension SolanaSDK: TokensRepository {}
