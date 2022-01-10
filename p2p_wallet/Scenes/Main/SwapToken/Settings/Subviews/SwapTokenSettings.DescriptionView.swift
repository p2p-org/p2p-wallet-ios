//
//  SwapTokenSettings.DescriptionView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 22.12.2021.
//

import BEPureLayout
import UIKit

extension SwapTokenSettings {
    final class DescriptionView: UIStackView {
        private let firstParagraph = ParagraphView()
        private let secondParagraph = ParagraphView()
        private let thirdParagraph = ParagraphView()
        private let fourthParagraph = ParagraphView()

        init() {
            super.init(frame: .zero)

            configureSelf()
            configureFirstParagraph()
            configureSecondParagraph()
            configureThirdParagraph()
            configureFourthParagraph()
            layout()
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func configureSelf() {
            axis = .vertical
            spacing = 12
        }

        private func layout() {
            let subviews = [firstParagraph, secondParagraph, thirdParagraph, fourthParagraph]

            subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            subviews.forEach(addArrangedSubview)
        }

        private func configureFirstParagraph() {
            let slippage = L10n.slippage
            let paragraph = createParagraphText(
                string: L10n.aIsADifferenceBetweenTheExpectedPriceAndTheActualPriceAtWhichATradeIsExecuted(slippage),
                mainSubstring: slippage
            )

            firstParagraph.setText(string: paragraph)
        }

        private func configureSecondParagraph() {
            let volatility = L10n.higherVolatility
            let paragraph = createParagraphText(
                string: L10n.slippageCanOccurAtAnyTimeButItIsMostPrevalentDuringPeriodsOf(volatility),
                mainSubstring: volatility
            )

            secondParagraph.setText(string: paragraph)
        }

        private func configureThirdParagraph() {
            let frontrun = L10n.frontrun
            let paragraph = createParagraphText(
                string: L10n.transactionsThatExceed20SlippageToleranceMayBe(frontrun),
                mainSubstring: frontrun
            )

            thirdParagraph.setText(string: paragraph)
        }

        private func configureFourthParagraph() {
            let exceed = L10n.cannotExceed50
            let paragraph = createParagraphText(
                string: L10n.slippageTolerance(exceed),
                mainSubstring: exceed
            )

            fourthParagraph.setText(string: paragraph)
        }

        private func createParagraphText(string: String, mainSubstring: String) -> NSAttributedString {
            let string = NSMutableAttributedString()
                .text(
                    string,
                    size: 12,
                    color: .h8e8e93
                )
            let range = (string.string as NSString).range(of: mainSubstring)
            string.addAttribute(.font, value: UIFont.systemFont(ofSize: 12, weight: .semibold), range: range)

            return string
        }
    }
}
