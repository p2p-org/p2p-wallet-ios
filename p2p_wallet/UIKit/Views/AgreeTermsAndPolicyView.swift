//
//  AgreeTermsAndPolicyView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 28.11.2021.
//

import UIKit
import BEPureLayout

final class AgreeTermsAndPolicyView: BEView, UITextViewDelegate {
    private lazy var label = UITextView()

    var didTouchTermsOfUse: (() -> Void)?
    var didTouchPrivacyPolicy: (() -> Void)?

    override func commonInit() {
        configureLabel()
        addSubviews()
        setConstraints()
    }

    private func addSubviews() {
        addSubview(label)
    }

    private func setConstraints() {
        label.autoPinEdgesToSuperviewEdges()
    }

    private func configureLabel() {
        label.isScrollEnabled = false
        label.isEditable = false
        label.delegate = self
        label.backgroundColor = .clear

        let normalFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let linkFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let linkAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.h5887ff]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17
        paragraphStyle.alignment = .center

        let attributedText = NSMutableAttributedString(
            string: L10n.byContinuingYouAgreeToWalletSAnd(L10n.termsOfUse, L10n.privacyPolicy),
            attributes: [
                .font: normalFont,
                .kern: -0.24,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.textBlack
            ]
        )

        let termsOfUseRange = (attributedText.string as NSString).range(of: L10n.termsOfUse)
        attributedText.addAttribute(.font, value: linkFont, range: termsOfUseRange)
        attributedText.addAttribute(.link, value: "termsOfUse", range: termsOfUseRange)

        let privacyPolicyRange = (attributedText.string as NSString).range(of: L10n.privacyPolicy)
        attributedText.addAttribute(.font, value: linkFont, range: privacyPolicyRange)
        attributedText.addAttribute(.link, value: "privacyPolicy", range: privacyPolicyRange)

        label.attributedText = attributedText
        label.linkTextAttributes = linkAttributes
    }

    // MARK: Delegate

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        switch URL.absoluteString {
        case "termsOfUse":
            didTouchTermsOfUse?()
        case "privacyPolicy":
            didTouchPrivacyPolicy?()
        default:
            assertionFailure(URL.absoluteString)
        }

        return false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        guard textView.selectedTextRange != nil else { return }

        textView.selectedTextRange = nil
    }
}
