//
//  WalletsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/03/2021.
//

import Action
import BECollectionView
import Foundation
import RxSwift

class WalletsCollectionView: BEStaticSectionsCollectionView {
    let walletsRepository: WalletsRepository

    init(
        header: BECollectionViewHeaderFooterViewLayout? = nil,
        walletsRepository: WalletsRepository,
        sections: [BEStaticSectionsCollectionView.Section],
        footer: BECollectionViewHeaderFooterViewLayout? = nil
    ) {
        self.walletsRepository = walletsRepository
        super.init(
            header: header,
            sections: sections,
            footer: footer
        )
    }

    override func dataDidChangeObservable() -> Observable<Void> {
        walletsRepository.dataDidChange
    }
}
