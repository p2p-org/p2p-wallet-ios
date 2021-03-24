//
//  ChooseWalletCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import BECollectionView

class ChooseWalletCollectionView: BECollectionView {
    // MARK: - Properties
    let viewModel: ChooseWalletViewModel
    
    // MARK: - Initializers
    init(viewModel: ChooseWalletViewModel, firstSectionFilter: ((AnyHashable) -> Bool)? = nil) {
        self.viewModel = viewModel
        
        var sections = [
            BECollectionViewSection(
                layout: BECollectionViewSectionLayout(
                    header: .init(viewClass: SecondSectionHeaderView.self),
                    cellType: Cell.self,
                    interGroupSpacing: 16
                ),
                viewModel: viewModel.myWalletsViewModel,
                customFilter: firstSectionFilter
            )
        ]
        
        if let viewModel = viewModel.otherWalletsViewModel {
            sections.append(
                BECollectionViewSection(
                    layout: BECollectionViewSectionLayout(
                        header: .init(viewClass: FirstSectionHeaderView.self),
                        cellType: OtherTokenCell.self,
                        interGroupSpacing: 16
                    ),
                    viewModel: viewModel,
                    customFilter: firstSectionFilter
                )
            )
        }
        
        super.init(sections: sections)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
