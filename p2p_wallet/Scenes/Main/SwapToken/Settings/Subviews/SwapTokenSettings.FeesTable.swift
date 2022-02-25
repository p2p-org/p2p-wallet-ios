//
//  SwapTokenSettings.FeesTable.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.12.2021.
//

import UIKit
import RxCocoa

extension SwapTokenSettings {
    final class FeesTable: BECompositionView {
        let cellsContentDriver: Driver<[FeeCellContent]>
        
        init(cellsContentDriver: Driver<[FeeCellContent]>) {
            self.cellsContentDriver = cellsContentDriver
            super.init()
        }
    
        override func build() -> UIView {
            WLCard {
                BEBuilder(driver: cellsContentDriver) { cellsContent in
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
