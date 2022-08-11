//
//  SwapTokenSettings.FeesTable.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.12.2021.
//

import Combine
import UIKit

extension SwapTokenSettings {
    final class FeesTable: BECompositionView {
        let cellsContentPublisher: AnyPublisher<[FeeCellContent], Never>

        init(cellsContentPublisher: AnyPublisher<[FeeCellContent], Never>) {
            self.cellsContentPublisher = cellsContentPublisher
            super.init()
        }

        override func build() -> UIView {
            WLCard {
                BEBuilder(publisher: cellsContentPublisher) { cellsContent in
                    BEVStack {
                        for content in cellsContent {
                            FeeCell().setUp(content: content)
                        }
                    }
                }
            }
        }
    }
}
