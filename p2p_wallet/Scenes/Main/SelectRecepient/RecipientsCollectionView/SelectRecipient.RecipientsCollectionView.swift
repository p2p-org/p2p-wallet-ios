//
//  SelectRecipient.RecipientsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/10/2021.
//

import Foundation
import BECollectionView

extension SelectRecipient {
    final class RecipientsCollectionView: BEStaticSectionsCollectionView {
        // MARK: - Dependencies
        private let recipientsListViewModel: RecipientsListViewModel
        
        // MARK: - Initializer
        init(recipientsListViewModel: RecipientsListViewModel) {
            self.recipientsListViewModel = recipientsListViewModel
            
            let section = BEStaticSectionsCollectionView.Section(
                index: 0,
                layout: .init(
                    header: .init(viewClass: SectionHeaderView.self, heightDimension: .absolute(40)),
                    cellType: RecipientCell.self,
                    itemHeight: .estimated(76)
                ),
                viewModel: recipientsListViewModel
            )
            
            super.init(sections: [section])
        }
        
        // MARK: -
        
        /// Do anything after a snapshot of data has been loaded (update header for example)
        override func dataDidLoad() {
            super.dataDidLoad()

            if let header = sectionHeaderView(sectionIndex: 0) as? SectionHeaderView {
                guard !recipientsListViewModel.isEmpty else {
                    return header.setTitle(nil)
                }

                let title = recipientsListViewModel.isSearchingByAddress
                    ? L10n.result
                    : L10n.foundAssociatedWalletAddress

                header.setTitle(title)
            }
        }
    }
}
