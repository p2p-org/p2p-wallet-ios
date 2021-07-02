//
//  TokensRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation
import RxSwift

protocol TokensRepository {
    func getTokensList() -> Single<[SolanaSDK.Token]>
}

extension SolanaSDK: TokensRepository {}
