//
//  EmptyTransactionsView.swift
//  p2p_wallet
//
//  Created by Ivan on 21.04.2022.
//

import BEPureLayout
import Combine
import UIKit

extension History {
    final class EmptyTransactionsView: BECompositionView {
        let refreshClicked = PassthroughSubject<Void, Never>()
        private var subscriptions = [AnyCancellable]()

        override func build() -> UIView {
            BEVStack(alignment: .center, distribution: .equalCentering) {
                UIView.spacer
                BEVStack(spacing: 30, alignment: .center, distribution: .equalCentering) {
                    UIImageView(width: 220, height: 220, image: .transactionsEmpty)
                    BEVStack(spacing: 32, alignment: .center) {
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
                        UIButton(
                            width: 177,
                            height: 48,
                            backgroundColor: .rain,
                            cornerRadius: 12,
                            label: L10n.refreshPage,
                            labelFont: .systemFont(ofSize: 16, weight: .semibold),
                            textColor: .black
                        ).setup {
                            $0.setImage(.refreshPage, for: .normal)
                            $0.titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 40)
                            $0.imageEdgeInsets = .init(top: 0, left: 134, bottom: 0, right: 0)
                        }
                        .onTap { [weak self] in
                            self?.refreshClicked.send()
                        }
                    }
                }
                UIView.spacer
            }
        }
    }
}
