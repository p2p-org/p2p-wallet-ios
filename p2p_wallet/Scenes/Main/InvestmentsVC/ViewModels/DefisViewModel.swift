//
//  DefisViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import BECollectionView
import Foundation
import RxSwift

class DefisViewModel: BEListViewModel<Defi> {
    override func createRequest() -> Single<[Defi]> {
        super.createRequest()
            .map { _ in
                [
                    Defi(name: "Token exchange 1"),
                    Defi(name: "Token exchange 2"),
                    Defi(name: "Token exchange 3"),
                ]
            }
    }
}
