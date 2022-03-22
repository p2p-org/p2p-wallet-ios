//
//  SelectRecipient.RecipientsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/10/2021.
//

import BECollectionView
import Foundation

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class RecipientsCollectionView: BEStaticSectionsCollectionView {
        // MARK: - Initializer

        init(recipientsListViewModel: RecipientsListViewModel) {
            let section = BEStaticSectionsCollectionView.Section(
                index: 0,
                layout: .init(
                    cellType: RecipientCell.self,
                    itemHeight: .estimated(76)
                ),
                viewModel: recipientsListViewModel
            )

            super.init(sections: [section])
        }
    }
}
