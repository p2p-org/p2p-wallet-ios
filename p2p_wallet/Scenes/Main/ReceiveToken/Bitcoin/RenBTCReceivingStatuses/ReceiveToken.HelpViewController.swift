//
//  ReceiveToken.HelpViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/06/2021.
//

import Foundation

extension ReceiveToken {
    class HelpViewController: WLBottomSheet {
        override var padding: UIEdgeInsets { .init(x: 0, y: 20) }

        override func setUp() {
            super.setUp()

            stackView.addArrangedSubviews {
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                    UIImageView(width: 32, height: 32, image: .questionMarkCircle, tintColor: .iconSecondary)
                    UILabel(text: L10n.solAndSPLTokens, textSize: 17, weight: .semibold)
                }
                .padding(.init(x: 20, y: 0))

                BEStackViewSpacing(16.67)

                UIView.defaultSeparator()

                BEStackViewSpacing(20)

                UILabel(
                    text: L10n
                        .TheSolanaProgramLibrarySPLIsACollectionOfOnChainProgramsMaintainedByTheSolanaTeam
                        .TheSPLTokenProgramIsTheTokenStandardOfTheSolanaBlockchain
                        .similarToERC20TokensOnTheEthereumNetworkSPLTokensAreDesignedForDeFiApplications,
                    textSize: 15,
                    numberOfLines: 0
                )
                    .padding(.init(x: 20, y: 0))
            }
        }
    }
}
