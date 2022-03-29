//
// Created by Giang Long Tran on 27.03.2022.
//

import BEPureLayout
import UIKit

extension SupportedTokens {
    class EmptyCell: BECollectionCell {
        var searchKey: String = "" {
            didSet {
                textLabel.text = L10n
                    .ifThereIsATokenNamedWeDonTRecommendSendingItToYourSolanaAddressSinceItWillMostLikelyBeLostForever(
                        searchKey
                    )
            }
        }

        private let textLabel = BERef<UILabel>()

        override func build() -> UIView {
            BEContainer {
                BEHStack(alignment: .center) {
                    UIImageView(width: 44, height: 44, image: .squircleTransactionError)
                    UILabel(
                        text: L10n
                            .ifThereIsATokenNamedWeDonTRecommendSendingItToYourSolanaAddressSinceItWillMostLikelyBeLostForever(
                                searchKey
                            ),
                        numberOfLines: 10
                    )
                        .bind(textLabel)
                        .padding(.init(x: 14, y: 18))
                }
            }
            .padding(.init(x: 18, y: 0), cornerRadius: 12.0, borderColor: .ff3b30)
            .backgroundColor(color: .fff5f5)
            .padding(.init(x: 18, y: 0))
        }
    }
}
