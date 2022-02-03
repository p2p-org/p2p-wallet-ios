//
//  SupportedTokens.CollectionViewHeader.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 31.01.2022.
//

extension SupportedTokens.CollectionView {
    final class TableHeaderView: BaseCollectionReusableView {
        private lazy var label = UIView.greyBannerView {
            createHint()
        }

        override func commonInit() {
            super.commonInit()
            stackView.addArrangedSubview(label.padding(.init(top: 0, left: 18, bottom: 12, right: 18)))
        }

        private func createHint() -> UILabel {
            let qrCodeHint = UILabel(numberOfLines: 0)
            let highlightedText = L10n.weDoNotRecommendSendingItToThisAddress
            let fullText = L10n
                .EachTokenInThisListIsAvailableForReceivingWithThisAddressYouCanSearchForATokenByTypingItsNameOrTicker
                .ifATokenIsNotOnThisListWeDoNotRecommendSendingItToThisAddress

            let normalFont = UIFont.systemFont(ofSize: 15, weight: .regular)
            let highlightedFont = UIFont.systemFont(ofSize: 15, weight: .bold)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.17
            paragraphStyle.alignment = .center

            let attributedText = NSMutableAttributedString(
                string: fullText,
                attributes: [
                    .font: normalFont,
                    .kern: -0.24,
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: UIColor.textBlack
                ]
            )

            let highlightedRange = (attributedText.string as NSString).range(of: highlightedText, options: .caseInsensitive)
            attributedText.addAttribute(.font, value: highlightedFont, range: highlightedRange)

            qrCodeHint.attributedText = attributedText

            return qrCodeHint
        }
    }
}
