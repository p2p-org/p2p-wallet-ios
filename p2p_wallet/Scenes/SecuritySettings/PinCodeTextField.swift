//
//  PinCodeTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class PinCodeTextField: BEView, UITextFieldDelegate {
    class ElementView: BEView {
        lazy var label = UILabel(textSize: 40, weight: .bold, textAlignment: .center)
        override func commonInit() {
            super.commonInit()
            addSubview(label)
            label.autoPinEdgesToSuperviewEdges()
            let separator = UIView(height: 2, backgroundColor: .textBlack)
            addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        }
    }
    
    private class TextField: UITextField {
        override init(frame: CGRect) {
            super.init(frame: .zero)
            textColor = .clear
            keyboardType = .numberPad
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        override func caretRect(for position: UITextPosition) -> CGRect {
            .zero
        }
    }
    
    private lazy var hiddenTextField = TextField(forAutoLayout: ())
    var text = "" { didSet { updateText() } }
    var numberOfDigits = 0 { didSet { updateStackView() } }
    
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 20, alignment: .fill, distribution: .fillEqually)
    
    override func commonInit() {
        super.commonInit()
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        addSubview(hiddenTextField)
        hiddenTextField.autoPinEdge(.top, to: .top, of: stackView)
        hiddenTextField.autoPinEdge(.bottom, to: .bottom, of: stackView)
        hiddenTextField.autoPinEdge(.left, to: .left, of: stackView)
        hiddenTextField.autoPinEdge(.right, to: .right, of: stackView)
        hiddenTextField.delegate = self
    }
    
    func updateStackView() {
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        for _ in 0..<numberOfDigits {
            stackView.addArrangedSubview(ElementView(width: 37, height: 50))
        }
        text = ""
    }
    
    func updateText() {
        let digits = String(text.suffix(numberOfDigits))
        let elementViews = stackView.arrangedSubviews.compactMap {$0 as? ElementView}
        for (index, view) in elementViews.enumerated() {
            if index < digits.count {
                view.label.text = "\(digits[index..<index+1])"
            } else {
                view.label.text = nil
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "" {
            if text.count > 0 {
                text = String(text.prefix(text.count-1))
            }
        } else if let number = Int(string.prefix(numberOfDigits-text.count)) {
            text += "\(number)"
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
}
