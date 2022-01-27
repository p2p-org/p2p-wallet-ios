//
//  ExpandableTextView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 12.11.2021.
//

import UIKit
import PureLayout
import RxSwift

final class ExpandableTextView: UIView {
    private let placeholderLabel = UILabel()
    private let textView = UITextView()
    private let horizontalStackView = UIStackView(
        axis: .horizontal,
        spacing: 4,
        alignment: .bottom,
        distribution: .fill
    )
    private let postfixLabel = UILabel()
    private let clearButton = ClearButton()

    private var topDynamicPlaceholderConstraint: NSLayoutConstraint?
    private var leftDynamicPlaceholderConstraint: NSLayoutConstraint?

    private let clearButtonWidth: CGFloat = 27
    private let clearButtonHeight: CGFloat = 36
    private let yMargin: CGFloat = 11

    private let changesFilter: TextChangesFilter?

    var rxText: Observable<String?> {
        textView.rx.text.asObservable()
    }

    private var didTouchView: (() -> Void)?

    var placeholder: String? {
        get {
            return placeholderLabel.text
        }
        set {
            changePlaceholderText(to: newValue)
        }
    }

    init(
        changesFilter: TextChangesFilter? = nil,
        limitOfLines: Int? = nil
    ) {
        self.changesFilter = changesFilter

        super.init(frame: .zero)

        configureSelf()
        configureSubviews(limitOfLines: limitOfLines)
        addSubviews()
        setConstraints()

        didTouchView = { [weak textView] in
            textView?.becomeFirstResponder()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    func setPostfix(text: String?) {
        postfixLabel.text = text
        postfixLabel.isHidden = text == nil
    }

    func set(text: String?) {
        if
            let changesFilter = changesFilter,
            let text = text,
            !changesFilter.isValid(string: text)
        {
            return
        }

        let textIsEmpty = text?.isEmpty ?? true
        changeTextViewText(to: text)
        animatePlaceholder(reversed: textIsEmpty, force: !textIsEmpty)
    }

    func paste() {
        textView.paste(nil)
    }
}

private extension ExpandableTextView {
    var allSubviews: [UIView] {
        return [horizontalStackView, placeholderLabel]
    }

    func configureSelf() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTouch))
        self.addGestureRecognizer(gestureRecognizer)
    }

    func configureSubviews(limitOfLines: Int?) {
        configureTextView(limitOfLines: limitOfLines)
        configurePlaceholderLabel()
        configureClearButton()
        configurePostfixLabel()
    }

    func configureTextView(limitOfLines: Int?) {
        textView.delegate = self
        textView.font = .systemFont(ofSize: 17, weight: .regular)
        textView.textColor = .textBlack
        textView.isScrollEnabled = false
        textView.spellCheckingType = .no
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no

        if let limitOfLines = limitOfLines {
            textView.textContainer.maximumNumberOfLines = limitOfLines
            textView.textContainer.lineBreakMode = .byTruncatingMiddle
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.58
        textView.attributedText = NSMutableAttributedString(
            string: "",
            attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle]
        )
    }

    func configurePlaceholderLabel() {
        placeholderLabel.textColor = .h8e8e93
        placeholderLabel.font = .systemFont(ofSize: 17)
    }

    func configureClearButton() {
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(didTouchClearButton), for: .touchUpInside)
    }

    func configurePostfixLabel() {
        postfixLabel.isHidden = true
        postfixLabel.textColor = .h8e8e93
        postfixLabel.font = .systemFont(ofSize: 17)
    }

    func addSubviews() {
        allSubviews.forEach(addSubview)

        horizontalStackView.addArrangedSubviews(
            [
                textView.padding(.init(only: .top, inset: yMargin)),
                postfixLabel,
                clearButton
            ]
        )
    }

    func setConstraints() {
        textView.setContentHuggingPriority(.required, for: .vertical)
        postfixLabel.setContentHuggingPriority(.required, for: .horizontal)
        placeholderLabel.setContentHuggingPriority(.required, for: .horizontal)

        horizontalStackView.autoPinEdgesToSuperviewEdges()
        postfixLabel.autoSetDimension(.height, toSize: clearButtonHeight)
        clearButton.autoSetDimensions(to: .init(width: clearButtonWidth, height: clearButtonHeight))
        topDynamicPlaceholderConstraint = placeholderLabel.autoPinEdge(toSuperviewEdge: .top, withInset: yMargin)
        leftDynamicPlaceholderConstraint =  placeholderLabel.autoPinEdge(toSuperviewEdge: .leading)
    }

    func animatePlaceholder(reversed: Bool, force: Bool = false) {
        let ratio: CGFloat = reversed ? 1 : 13 / 17
        let oldWidth = placeholderLabel.intrinsicContentSize.width
        let newWidth = oldWidth * ratio
        let leftOffset = (oldWidth - newWidth) / 2

        topDynamicPlaceholderConstraint?.constant = reversed ? 18.5 : 0
        leftDynamicPlaceholderConstraint?.constant = -leftOffset
        let layout = {
            self.placeholderLabel.transform = CGAffineTransform(scaleX: ratio, y: ratio)
            self.layoutIfNeeded()
        }

        force ? layout() : UIView.animate(withDuration: 0.3, animations: layout)
    }

    func changePlaceholderText(to string: String?) {
        placeholderLabel.text = string
        animatePlaceholder(reversed: self.placeholderLabel.transform == .identity, force: true)
    }

    func changeTextViewText(to newString: String?) {
        textViewTextDidChange(to: newString)
        textView.text = newString
    }

    func textViewTextDidChange(to newString: String?) {
        let stringIsEmpty = newString?.isEmpty ?? true
        clearButton.isHidden = stringIsEmpty
    }

    @objc
    func didTouch() {
        guard let didTouchView = didTouchView else { return assertionFailure("It must be set") }

        didTouchView()
    }

    @objc
    func didTouchClearButton() {
        changeTextViewText(to: nil)
        textView.becomeFirstResponder()
    }
}

extension ExpandableTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text?.isEmpty ?? true {
            animatePlaceholder(reversed: false)
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let text = textView.text
        if text?.isEmpty ?? true {
            animatePlaceholder(reversed: true)
        }
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let updatedText: String? = textView.text.flatMap {
            guard let textRange = Range(range, in: $0) else { return nil }

            return $0.replacingCharacters(in: textRange, with: text)
        }

        let isFilterValid = changesFilter
            .map {
                $0.isValid(textContainer: textView, string: text, range: range)
            } ?? true

        guard isFilterValid else {
            return false
        }

        textViewTextDidChange(to: updatedText)

        return true
    }
}
