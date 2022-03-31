//
//  WLPinCodeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/11/2021.
//

import BEPureLayout
import Foundation
import UIKit

private let pincodeLength = 6

final class WLPinCodeView: BEView {
    // MARK: - Properties

    /// Correct pincode for comparision, if not defined, the validation will always returns true
    private let correctPincode: String?

    /// Max attempts for retrying, default is nil (infinity)
    private let maxAttemptsCount: Int?

    private var currentPincode: String? {
        didSet {
            validatePincode()
            #if DEBUG
                currentPincodeLabel.text = currentPincode
            #endif
        }
    }

    private var attemptsCount: Int = 0

    var stackViewSpacing: CGFloat = 68 {
        didSet {
            stackView.spacing = stackViewSpacing
        }
    }

    private var isPresentingError = false

    // MARK: - Callbacks

    /// onSuccess, return newPincode if needed
    var onSuccess: ((String?) -> Void)?
    var onFailed: (() -> Void)?
    var onFailedAndExceededMaxAttemps: (() -> Void)?

    // MARK: - Subviews

    private lazy var stackView = UIStackView(
        axis: .vertical,
        spacing: stackViewSpacing,
        alignment: .center,
        distribution: .fill
    ) {
        #if DEBUG
            UILabel(text: correctPincode, textColor: .red, textAlignment: .center)
            BEStackViewSpacing(10)
            currentPincodeLabel
            BEStackViewSpacing(10)
        #endif
        dotsView
        numpadView
    }

    private let dotsView = _PinCodeDotsView()
    let errorLabel = UILabel(
        textSize: 13,
        weight: .semibold,
        textColor: .ff3b30,
        numberOfLines: 0,
        textAlignment: .center
    )
    private lazy var numpadView = _NumpadView(bottomLeftButton: bottomLeftButton)
    private let bottomLeftButton: UIView?

    #if DEBUG
        private lazy var currentPincodeLabel = UILabel(text: nil, textColor: .red)
    #endif

    // MARK: - Initializer

    init(correctPincode: String? = nil, maxAttemptsCount: Int? = nil, bottomLeftButton: UIView? = nil) {
        self.correctPincode = correctPincode
        self.maxAttemptsCount = maxAttemptsCount
        self.bottomLeftButton = bottomLeftButton
        super.init(frame: .zero)
    }

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        // stack view
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()

        // error label
        addSubview(errorLabel)
        errorLabel.autoPinEdge(toSuperviewSafeArea: .leading)
        errorLabel.autoPinEdge(toSuperviewSafeArea: .trailing)
        errorLabel.autoPinEdge(.top, to: .bottom, of: dotsView, withOffset: 10)

        // calbacks
        numpadView.didChooseNumber = { [weak self] in self?.add(digit: $0) }

        numpadView.didTapDelete = { [weak self] in self?.backspace() }

        // initial setup
        currentPincode = nil
    }

    // MARK: - Public methods

    func reset() {
        attemptsCount = 0
        currentPincode = nil
    }

    func setBlock(_ isBlocked: Bool) {
        numpadView.isUserInteractionEnabled = !isBlocked
    }

    // MARK: - Private methods

    private func add(digit: Int) {
        guard digit >= 0, digit < 10 else { return }

        isPresentingError = false

        // calculate value
        let newValue = (currentPincode ?? "") + String(digit) // (currentPincode ?? 0) * 10 + UInt(digit)
        let numberOfDigits = newValue.count

        // override
        guard numberOfDigits <= pincodeLength else {
            currentPincode = String(digit)
            return
        }

        currentPincode = newValue
    }

    private func backspace() {
        guard let currentPincode = currentPincode, currentPincode.count > 1 else {
            currentPincode = nil
            return
        }
        self.currentPincode = String(currentPincode.dropLast())
    }

    private func validatePincode() {
        // reset
        errorLabel.isHidden = true
        numpadView.isUserInteractionEnabled = true

        // pin code nil
        guard let currentPincode = currentPincode,
              currentPincode.count <= pincodeLength
        else {
            dotsView.pincodeEntered(numberOfDigits: 0)
            return
        }

        // highlight dots
        let numberOfDigits = currentPincode.count
        dotsView.pincodeEntered(numberOfDigits: numberOfDigits)

        // delete button

        // verify
        if numberOfDigits == pincodeLength {
            // if no correct pincode, mark as success
            guard let correctPincode = correctPincode else {
                pincodeSuccess()
                return
            }

            // correct pincode
            if currentPincode == correctPincode {
                pincodeSuccess()
            }

            // incorrect pincode with max attempts
            else if let maxAttemptsCount = maxAttemptsCount {
                // increase attempts count
                attemptsCount += 1

                // compare current attempt with max attempts
                if attemptsCount >= maxAttemptsCount {
                    pincodeFailed(exceededMaxAttempts: true)
                } else {
                    pincodeFailed(exceededMaxAttempts: false)
                }
            }

            // incorrect pincode without max attempts
            else {
                pincodeFailed(exceededMaxAttempts: false)
            }
        }
    }

    private func pincodeSuccess() {
        dotsView.pincodeSuccess()
        onSuccess?(currentPincode)
        attemptsCount = 0
        if correctPincode != nil {
            numpadView.isUserInteractionEnabled = false
        }
    }

    private func pincodeFailed(exceededMaxAttempts: Bool) {
        dotsView.pincodeFailed()
        errorLabel.isHidden = false
        if let maxAttemptsCount = maxAttemptsCount {
            errorLabel.text = L10n.incorrectPINTryAgainAttemptLeft(maxAttemptsCount - attemptsCount)
        } else {
            errorLabel.text = L10n.PINDoesnTMatch.tryAgain
        }

        if exceededMaxAttempts {
            numpadView.isUserInteractionEnabled = false
            onFailedAndExceededMaxAttemps?()
        } else {
            onFailed?()
        }
    }

    private func clearErrorAfter3Seconds() {
        // clear pincode after 3 seconds
        isPresentingError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
            guard let self = self, self.isPresentingError else { return }
            self.currentPincode = nil
        }
    }
}

private class _PinCodeDotsView: BEView {
    // MARK: - Constants

    private let dotSize: CGFloat = 12.adaptiveHeight
    private let cornerRadius: CGFloat = 12.adaptiveHeight
    private let padding: UIEdgeInsets = .init(x: 12.adaptiveHeight, y: 8.adaptiveHeight)

    // MARK: - Properties

    private var indicatorViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Subviews

    private lazy var dots: [UIView] = {
        var views = [UIView]()
        for index in 0 ..< pincodeLength {
            let dot = UIView(width: dotSize, height: dotSize, backgroundColor: .d1d1d6, cornerRadius: dotSize / 2)
            views.append(dot)
        }
        return views
    }()

    private lazy var indicatorView = UIView(backgroundColor: .h82a5ff, cornerRadius: cornerRadius)

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        // background indicator
        indicatorViewHeightConstraint = indicatorView.autoSetDimension(.width, toSize: 0)
        addSubview(indicatorView)
        indicatorView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)

        // dots stack view
        let stackView = UIStackView(axis: .horizontal, spacing: padding.left * 2, alignment: .fill, distribution: .fill)
        stackView.addArrangedSubviews(dots)
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: padding)
    }

    // MARK: - Actions

    func pincodeEntered(numberOfDigits: Int) {
        guard numberOfDigits <= pincodeLength else { return }
        indicatorViewHeightConstraint.constant = (dotSize + (padding.left * 2)) * CGFloat(numberOfDigits)
        indicatorView.backgroundColor = .h82a5ff
        for i in 0 ..< dots.count {
            if i < numberOfDigits {
                dots[i].backgroundColor = .h5887ff
            } else {
                dots[i].backgroundColor = .d1d1d6
            }
        }
        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
        }
    }

    func pincodeFailed() {
        indicatorView.backgroundColor = .f88686
        dots.forEach { $0.backgroundColor = .ff3b30 }
    }

    func pincodeSuccess() {
        indicatorView.backgroundColor = .attentionGreen
        dots.forEach { $0.backgroundColor = .h34c759 }
    }
}

private class _NumpadView: BEView {
    // MARK: - Constants

    private let buttonSize: CGFloat = 72
    private let spacing = 30.adaptiveHeight
    private let deleteButtonColor = StateColor(normal: .h8e8e93, tapped: .textBlack)

    // MARK: - Callback

    var didChooseNumber: ((Int) -> Void)?
    var didTapDelete: (() -> Void)?

    // MARK: - Subviews

    private let bottomLeftButton: UIView?
    private lazy var numButtons: [_ButtonView] = {
        var views = [_ButtonView]()
        for index in 0 ..< 10 {
            let view = _ButtonView(width: buttonSize, height: buttonSize, cornerRadius: buttonSize / 2)
            view.label.text = "\(index)"
            view.tag = index
            view.onTap(self, action: #selector(numButtonDidTap(_:)))
            views.append(view)
        }
        return views
    }()

    private lazy var deleteButton = UIImageView(
        width: buttonSize,
        height: buttonSize,
        image: .pincodeDelete,
        tintColor: deleteButtonColor.normal
    )
        .onTap(self, action: #selector(deleteButtonDidTap))

    fileprivate init(bottomLeftButton: UIView? = nil) {
        self.bottomLeftButton = bottomLeftButton
        super.init(frame: .zero)
        configureForAutoLayout()
    }

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: spacing, alignment: .fill, distribution: .fillEqually)

        stackView.addArrangedSubview(buttons(from: 1, to: 3))
        stackView.addArrangedSubview(buttons(from: 4, to: 6))
        stackView.addArrangedSubview(buttons(from: 7, to: 9))
        stackView.addArrangedSubview(
            UIStackView(axis: .horizontal, spacing: spacing, alignment: .fill, distribution: .fillEqually) {
                bottomLeftButton ?? UIView.spacer
                numButtons[0]
                deleteButton
            }
        )

        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }

    // MARK: - Actions

    func setDeleteButtonHidden(_ isHidden: Bool) {
        deleteButton.alpha = isHidden ? 0 : 1
        deleteButton.isUserInteractionEnabled = !isHidden
    }

    @objc private func numButtonDidTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view as? _ButtonView else { return }
        didChooseNumber?(view.tag)
        view.animateTapping()
    }

    @objc private func deleteButtonDidTap() {
        didTapDelete?()

        UIView.animate(withDuration: 0.1) {
            self.deleteButton.tintColor = self.deleteButtonColor.tapped
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.deleteButton.tintColor = self.deleteButtonColor.normal
            }
        }
    }

    // MARK: - Helpers

    private func buttons(from: Int, to: Int) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: spacing, alignment: .fill, distribution: .fillEqually)
        for i in from ..< to + 1 {
            stackView.addArrangedSubview(numButtons[i])
        }
        return stackView
    }
}

private class _ButtonView: BEView {
    // MARK: - Constant

    private let textSize: CGFloat = 32
    private let customBgColor = StateColor(normal: .fafafc, tapped: .passcodeHighlightColor)
    private let textColor = StateColor(normal: .black, tapped: .white)

    // MARK: - Subviews

    fileprivate lazy var label = UILabel(textSize: textSize, weight: .semibold, textColor: textColor.normal)

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        backgroundColor = customBgColor.normal

        addSubview(label)
        label.autoCenterInSuperview()
    }

    fileprivate func animateTapping() {
        layer.backgroundColor = customBgColor.tapped.cgColor
        label.textColor = textColor.tapped
        UIView.animate(withDuration: 0.05) {
            self.layer.backgroundColor = self.customBgColor.normal.cgColor
            self.label.textColor = self.textColor.normal
        }
    }
}

private struct StateColor {
    let normal: UIColor
    let tapped: UIColor
}
