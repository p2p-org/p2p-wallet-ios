//
//  EmptyTransactionsView.swift
//  p2p_wallet
//
//  Created by Ivan on 21.04.2022.
//

import BEPureLayout
import UIKit

extension History {
    final class EmptyTransactionsView: BECompositionView {
        override func build() -> UIView {
            BEVStack(alignment: .center, distribution: .equalCentering) {
                UIView.spacer
                BEVStack(spacing: 30, alignment: .center, distribution: .equalCentering) {
                    UIImageView(width: 220, height: 220, image: .transactionsEmpty)
                    BEVStack(spacing: 16, alignment: .center) {
                        UILabel(
                            text: L10n.noTransactionsYet,
                            textSize: 20,
                            weight: .semibold,
                            textAlignment: .center
                        )
                        UILabel(
                            text: L10n.afterFirstTransactionYouWillBeAbleToViewItHere,
                            textSize: 15,
                            textColor: .textSecondary,
                            numberOfLines: 0,
                            textAlignment: .center
                        )
                    }
                }
                UIView.spacer
            }
        }
    }
}
