//
//  WLPinCodeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/11/2021.
//

import Foundation
import UIKit

final class WLPinCodeView: BEView {
    // MARK: - Subviews
    private let dotsView = _PinCodeDotsView()
    private let numpadView = _NumpadView()
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 68.adaptiveHeight, alignment: .center, distribution: .fill) {
            dotsView
            numpadView
        }
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
}

private class _PinCodeDotsView: BEView {
    // MARK: - Constants
    private let pincodeLength = 6
    private let dotSize: CGFloat = 12
    private let cornerRadius: CGFloat = 12
    private let padding: UIEdgeInsets = .init(x: 12, y: 8)
    
    // MARK: - Properties
    private var indicatorViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Subviews
    private lazy var dots = [0..<pincodeLength].map { _ in
        UIView(width: dotSize, height: dotSize, backgroundColor: .d1d1d6, cornerRadius: dotSize/2)
    }
    private lazy var indicatorView = UIView(backgroundColor: .h82a5ff, cornerRadius: cornerRadius)
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        // dots stack view
        let stackView = UIStackView(axis: .horizontal, spacing: padding.left * 2, alignment: .fill, distribution: .fill)
        stackView.addArrangedSubviews(dots)
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: padding)
        
        // background indicator
        indicatorViewHeightConstraint = indicatorView.autoSetDimension(.width, toSize: 0)
        addSubview(indicatorView)
        indicatorView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)
    }
    
    // MARK: - Actions
    func pincodeEntered(numberOfDigits: Int) {
        guard numberOfDigits <= pincodeLength else {return}
        indicatorViewHeightConstraint.constant = (dotSize + (padding.left * 2)) * CGFloat(numberOfDigits)
        indicatorView.backgroundColor = .h82a5ff
        dots.forEach {$0.backgroundColor = .d1d1d6}
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    func pincodeFailed() {
        indicatorView.backgroundColor = .alert
        dots.forEach {$0.backgroundColor = .ff3b30}
    }
    
    func pincodeSuccess() {
        indicatorView.backgroundColor = .attentionGreen
        dots.forEach {$0.backgroundColor = .d1d1d6}
    }
}

private class _NumpadView: BEView {
    private struct StateColor {
        let normal: UIColor
        let tapped: UIColor
    }
    
    // MARK: - Constants
    private let buttonSize = 72.adaptiveHeight
    private let textSize = 32.adaptiveHeight
    private let spacing = 30.adaptiveHeight
    
    private let buttonBgColor = StateColor(normal: .fafafc, tapped: .passcodeHighlightColor)
    private let buttonTextColor = StateColor(normal: .black, tapped: .white)
    
    // MARK: - Subviews
    
}
