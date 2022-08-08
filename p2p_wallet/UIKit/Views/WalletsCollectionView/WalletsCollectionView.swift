//
//  WalletsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/03/2021.
//

import BECollectionView_Combine
import Combine
import Foundation

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

    override func dataDidChangePublisher() -> AnyPublisher<Void, Never> {
        walletsRepository.dataDidChange
    }
}
