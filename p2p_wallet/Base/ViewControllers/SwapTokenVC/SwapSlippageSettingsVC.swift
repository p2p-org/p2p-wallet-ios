//
//  SwapSlippageSettingsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/01/2021.
//

import Foundation
import RxCocoa

class SwapSlippageSettingsVC: WLModalVC {
    // MARK: - Properties
    private let quickSelectableSlippages: [Double] = [0.1, 0.5, 1, 5]
    let slippage = BehaviorRelay<Double>(value: Defaults.slippage)
    var shouldShowTextField = false
    var isShowingTextField = false
    
    // MARK: - Subviews
    lazy var slippagesView = UIStackView(
        axis: .horizontal,
        spacing: 10,
        alignment: .fill,
        distribution: .equalSpacing,
        arrangedSubviews:
            quickSelectableSlippages.enumerated().map {createButton(text: "\($1)%", tag: $0)} +
            [
                UIImageView(width: 25, height: 24, image: .slippageEdit)
                    .padding(.init(all: 11), backgroundColor: .f6f6f8, cornerRadius: 12)
                    .onTap(self, action: #selector(buttonCustomSlippageDidTouch))
            ]
    )
    lazy var customSlippageTextField = BEDecimalTextField(height: 56, backgroundColor: .f6f6f8, cornerRadius: 12, font: .systemFont(ofSize: 17), textColor: .black, placeholder: L10n.slippage, autocorrectionType: .no, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .no, horizontalPadding: 16)
    
    // MARK: - Initializers
    override init() {
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowOrHide), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowOrHide), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubviews([
            UILabel(text: L10n.slippageSettings, textSize: 17, weight: .semibold)
                .padding(.init(x: 20, y: 0)),
            UIView.separator(height: 1, color: .separator),
            UILabel(
                text: L10n
                    .SlippageRefersToTheDifferenceBetweenTheExpectedPriceOfATradeAndThePriceAtWhichTheTradeIsExecuted
                    .slippageCanOccurAtAnyTimeButIsMostPrevalentDuringPeriodsOfHigherVolatilityWhenMarketOrdersAreUsed, textColor: .textSecondary, numberOfLines: 0
            )
                .padding(.init(x: 20, y: 0)),
            slippagesView
                .padding(.init(x: 20, y: 0)),
            customSlippageTextField
                .padding(.init(x: 20, y: 0))
        ])
        
        customSlippageTextField.delegate = self
        reloadData()
    }
    
    override func bind() {
        super.bind()
        slippage
            .subscribe { (_) in
                self.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    func reloadData() {
        var selectedView: UIView!
        if !shouldShowTextField,
           let index = quickSelectableSlippages.firstIndex(of: slippage.value)
        {
            selectedView = slippagesView.arrangedSubviews[index]
        } else {
            selectedView = slippagesView.arrangedSubviews.last
            shouldShowTextField = true
        }
        
        // config styles
        let deselectedViews = slippagesView.arrangedSubviews.filter {$0 != selectedView}
        selectedView.backgroundColor = .white
        selectedView.border(width: 1, color: .h5887ff)
        
        deselectedViews.forEach {
            $0.backgroundColor = .f6f6f8
            $0.border(width: 0, color: .clear)
        }
        
        // force relayout modal when needed
        customSlippageTextField.wrapper?.isHidden = !shouldShowTextField
        if shouldShowTextField != isShowingTextField {
            forceResizeModal()
            isShowingTextField.toggle()
        }
    }
    
    // MARK: - Helpers
    func createButton(text: String, tag: Int) -> UIView {
        UILabel(text: text, weight: .medium, textColor: .a3a5ba)
            .padding(.init(x: 10, y: 14), backgroundColor: .f6f6f8, cornerRadius: 12)
            .withTag(tag)
            .onTap(self, action: #selector(buttonSelectableSlippageDidTouch(_:)))
    }
    
    @objc func buttonSelectableSlippageDidTouch(_ sender: UIGestureRecognizer) {
        if let index = sender.view?.tag {
            shouldShowTextField = false
            slippage.accept(quickSelectableSlippages[index])
            customSlippageTextField.resignFirstResponder()
        }
    }
    
    @objc func buttonCustomSlippageDidTouch() {
        shouldShowTextField = true
        reloadData()
        customSlippageTextField.becomeFirstResponder()
    }
    
    @objc func keyboardDidShowOrHide() {
        forceResizeModal()
    }
}

extension SwapSlippageSettingsVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = FlexibleHeightPresentationController(position: .bottom, presentedViewController: presented, presenting: presenting)
        pc.animateResizing = false
        return pc
    }
}

extension SwapSlippageSettingsVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == customSlippageTextField {
            return customSlippageTextField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
