// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import UIKit

let pincodeLength = 6

struct PincodeStateColor {
    let normal: UIColor
    let tapped: UIColor
}

public final class PinCode: BEView {
    // MARK: - Properties

    public var stackViewSpacing: CGFloat = 10 {
        didSet {
            stackView.spacing = stackViewSpacing
        }
    }

    /// Put an delay after failure and reset, default is nil (no reset after failure)
    public var resetingDelayInSeconds: Int?

    /// Correct pincode for comparision, if not defined, the validation will always returns true
    private let correctPincode: String?

    /// Max attempts for retrying, default is nil (infinity)
    private let maxAttemptsCount: Int?

    private var currentPincode: String? {
        didSet {
            validatePincode()
        }
    }

    private var attemptsCount: Int = 0

    private var isPresentingError = false

    // MARK: - Callbacks

    /// onSuccess, return newPincode if needed
    public var onSuccess: ((String?) -> Void)?
    public var onFailed: (() -> Void)?
    public var onFailedAndExceededMaxAttemps: (() -> Void)?

    // MARK: - Subviews

    private lazy var stackView = UIStackView(
        axis: .vertical,
        spacing: stackViewSpacing,
        alignment: .center,
        distribution: .fill
    ) {
        dotsView
        numpadView
    }

    private let dotsView = PinCodeDotsView()
    let errorLabel = UILabel(
        textSize: 13,
        weight: .semibold,
        textColor: Asset.Colors.rose.color,
        numberOfLines: 0,
        textAlignment: .center
    )
    private lazy var numpadView = NumpadView(bottomLeftButton: bottomLeftButton)
    private let bottomLeftButton: UIView?

    // MARK: - Initializer

    public init(correctPincode: String? = nil, maxAttemptsCount: Int? = nil, bottomLeftButton: UIView? = nil) {
        self.correctPincode = correctPincode
        self.maxAttemptsCount = maxAttemptsCount
        self.bottomLeftButton = bottomLeftButton
        super.init(frame: .zero)
    }

    // MARK: - Methods

    override public func commonInit() {
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

    public func reset() {
        attemptsCount = 0
        currentPincode = nil
    }

    public func setBlock(_ isBlocked: Bool) {
        numpadView.isUserInteractionEnabled = !isBlocked
    }

    // MARK: - Private methods

    private func add(digit: Int) {
        guard digit >= 0, digit < 10 else { return }

        vibrate()
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

        vibrate()
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
        vibrate()
        onSuccess?(currentPincode)
        attemptsCount = 0
        if correctPincode != nil {
            numpadView.isUserInteractionEnabled = false
        }
    }

    private func pincodeFailed(exceededMaxAttempts: Bool) {
        dotsView.pincodeFailed()
        vibrate()
        // errorLabel.isHidden = false
        // if let maxAttemptsCount = maxAttemptsCount {
        //     errorLabel.text = L10n.incorrectPINTryAgainAttemptLeft(maxAttemptsCount - attemptsCount)
        // } else {
        //     errorLabel.text = L10n.PINDoesnTMatch.tryAgain
        // }

        if exceededMaxAttempts {
            numpadView.isUserInteractionEnabled = false
            onFailedAndExceededMaxAttemps?()
        } else {
            onFailed?()
            clearErrorWithDelay()
        }
    }

    private func clearErrorWithDelay() {
        guard let resetingDelayInSeconds = resetingDelayInSeconds else {
            return
        }
        
        // clear pincode after 3 seconds
        isPresentingError = true
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .seconds(resetingDelayInSeconds)
        ) { [weak self] in
            guard let self = self, self.isPresentingError else { return }
            self.currentPincode = nil
        }
    }

    private func vibrate() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
