//
//  WLPinCodeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/11/2021.
//

import Foundation
import UIKit

private let pincodeLength = 6

final class WLPinCodeView: BEView {
    // MARK: - Properties
    private let correctPincode: UInt = 123456 // TODO
    private var currentPincode: UInt? {
        didSet {
            validatePincode()
        }
    }
    
    // MARK: - Subviews
    private let dotsView = _PinCodeDotsView()
    private let numpadView = _NumpadView()
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 68, alignment: .center, distribution: .fill) {
            dotsView
            numpadView
        }
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        numpadView.didChooseNumber = {[weak self] num in
            // calculate value
            let newValue = (self?.currentPincode ?? 0) * 10 + UInt(num)
            let numberOfDigits = String(newValue).count
            
            // override
            guard numberOfDigits <= pincodeLength else {
                self?.currentPincode = UInt(num)
                return
            }

            self?.currentPincode = newValue
        }
        
        numpadView.didTapDelete = { [weak self] in
            guard let self = self, let currentPincode = self.currentPincode else {
                return
            }
            
            let numberOfDigits = String(currentPincode).count
            if numberOfDigits == 1 {
                self.currentPincode = nil
                return
            }
            
            self.currentPincode = currentPincode / 10
        }
        
        // setup
        currentPincode = nil
    }
    
    private func validatePincode() {
        // pin code nil
        guard let currentPincode = currentPincode,
              String(currentPincode).count <= pincodeLength
        else {
            numpadView.setDeleteButtonHidden(true)
            dotsView.pincodeEntered(numberOfDigits: 0)
            return
        }
        
        // highlight dots
        let numberOfDigits = String(currentPincode).count
        dotsView.pincodeEntered(numberOfDigits: numberOfDigits)
        
        // delete button
        numpadView.setDeleteButtonHidden(numberOfDigits == 0)
        
        // verify
        if numberOfDigits == pincodeLength {
            if currentPincode == correctPincode {
                dotsView.pincodeSuccess()
            } else {
                dotsView.pincodeFailed()
            }
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
        for index in 0..<pincodeLength {
            let dot = UIView(width: dotSize, height: dotSize, backgroundColor: .d1d1d6, cornerRadius: dotSize/2)
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
        guard numberOfDigits <= pincodeLength else {return}
        indicatorViewHeightConstraint.constant = (dotSize + (padding.left * 2)) * CGFloat(numberOfDigits)
        indicatorView.backgroundColor = .h82a5ff
        for i in 0..<dots.count {
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
        indicatorView.backgroundColor = .alert
        dots.forEach {$0.backgroundColor = .ff3b30}
    }
    
    func pincodeSuccess() {
        indicatorView.backgroundColor = .attentionGreen
        dots.forEach {$0.backgroundColor = .h34c759}
    }
}

private class _NumpadView: BEView {
    // MARK: - Constants
    private let buttonSize = 72.adaptiveHeight
    private let spacing = 30.adaptiveHeight
    
    // MARK: - Callback
    var didChooseNumber: ((Int) -> Void)?
    var didTapDelete: (() -> Void)?
    
    // MARK: - Subviews
    private lazy var numButtons: [_ButtonView] = {
        var views = [_ButtonView]()
        for index in 0..<10 {
            let view = _ButtonView(width: buttonSize, height: buttonSize, cornerRadius: buttonSize/2)
            view.label.text = "\(index)"
            view.tag = index
            view.onTap(self, action: #selector(numButtonDidTap(_:)))
            views.append(view)
        }
        return views
    }()
    
    private lazy var deleteButton = UIImageView(width: buttonSize, height: buttonSize, image: .pincodeDelete, tintColor: .h8e8e93)
        .onTap(self, action: #selector(deleteButtonDidTap))
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: spacing, alignment: .fill, distribution: .fillEqually)
        
        stackView.addArrangedSubview(buttons(from: 1, to: 3))
        stackView.addArrangedSubview(buttons(from: 4, to: 6))
        stackView.addArrangedSubview(buttons(from: 7, to: 9))
        stackView.addArrangedSubview(
            UIStackView(axis: .horizontal, spacing: spacing, alignment: .fill, distribution: .fillEqually) {
                UIView.spacer
                numButtons[0]
                deleteButton
            }
        )
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    // MARK: - Actions
    func setDeleteButtonHidden(_ isHidden: Bool) {
        deleteButton.alpha = isHidden ? 0: 1
        deleteButton.isUserInteractionEnabled = !isHidden
    }
    
    @objc private func numButtonDidTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view as? _ButtonView else {return}
        didChooseNumber?(view.tag)
        view.animateTapping()
    }
    
    @objc private func deleteButtonDidTap() {
        didTapDelete?()
    }
    
    // MARK: - Helpers
    private func buttons(from: Int, to: Int) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: spacing, alignment: .fill, distribution: .fillEqually)
        for i in from..<to+1 {
            stackView.addArrangedSubview(numButtons[i])
        }
        return stackView
    }
}

private class _ButtonView: BEView {
    private struct StateColor {
        let normal: UIColor
        let tapped: UIColor
    }
    
    // MARK: - Constant
    private let textSize = 32.adaptiveHeight
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
        UIView.animate(withDuration: 0.1) {
            self.layer.backgroundColor = self.customBgColor.tapped.cgColor
            self.label.textColor = self.textColor.tapped
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.layer.backgroundColor = self.customBgColor.normal.cgColor
                self.label.textColor = self.textColor.normal
            }
        }
    }
}
