//
//  TokensRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation
import RxSwift
import SolanaSwift

protocol TokensRepository {
    func getTokensList() -> Single<[Token]>
}

extension SolanaSDK: TokensRepository {}
