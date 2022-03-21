//
//  AgreeTermsAndConditionsView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 19.11.2021.
//

import BEPureLayout
import UIKit

final class AgreeTermsAndConditionsView: BEView, UITextViewDelegate {
    private lazy var termsAndConditionsLabel: UIView = createAgreeLabel()

    var didTouchHyperLink: (() -> Void)?

    override func commonInit() {
        addSubviews()
        setConstraints()
    }

    private func addSubviews() {
        addSubview(termsAndConditionsLabel)
    }

    private func setConstraints() {
        termsAndConditionsLabel.autoPinEdgesToSuperviewEdges()
    }

    private func createAgreeLabel() -> UIView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.delegate = self
        textView.backgroundColor = .clear

        let normalFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let linkFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let linkAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.h5887ff]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17
        paragraphStyle.alignment = .center

        let attributedText = NSMutableAttributedString(
            string: L10n.byContinuingYouAgreeToWalletS(L10n.capitalizedTermsAndConditions),
            attributes: [
                .font: normalFont,
                .kern: -0.24,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.textBlack,
            ]
        )
        let linkRange = (attributedText.string as NSString).range(of: L10n.capitalizedTermsAndConditions)
        attributedText.addAttribute(.font, value: linkFont, range: linkRange)
        attributedText.addAttribute(.link, value: "", range: linkRange)
        textView.attributedText = attributedText
        textView.linkTextAttributes = linkAttributes

        return textView
    }

    // MARK: Delegate

    func textView(
        _: UITextView,
        shouldInteractWith _: URL,
        in _: NSRange,
        interaction _: UITextItemInteraction
    ) -> Bool {
        didTouchHyperLink?()
        return false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        guard textView.selectedTextRange != nil else { return }

        textView.selectedTextRange = nil
    }
}
