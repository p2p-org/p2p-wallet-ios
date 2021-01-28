//
//  SwapTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

class SwapTokenVC: WLModalWrapperVC {
    override var padding: UIEdgeInsets {super.padding.modifying(dLeft: .defaultPadding, dRight: .defaultPadding)}
    
    init(fromWallet: Wallet? = nil, toWallet: Wallet? = nil) {
        let vc = _SwapTokenVC(fromWallet: fromWallet, toWallet: toWallet)
        super.init(wrapped: vc)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.addArrangedSubviews([
            UIImageView(width: 24, height: 24, image: .walletSwap, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
            UILabel(text: L10n.swap, textSize: 17, weight: .semibold),
            UIImageView(width: 36, height: 36, image: .slippageSettings, tintColor: .a3a5ba)
        ])
        
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
}

class _SwapTokenVC: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal(backgroundColor: .vcBackground) }
    override var padding: UIEdgeInsets { UIEdgeInsets(top: .defaultPadding, left: 16, bottom: 0, right: 16) }
    
    let viewModel = SwapTokenVM()
    var fromWallet = BehaviorRelay<Wallet?>(value: nil)
    var toWallet = BehaviorRelay<Wallet?>(value: nil)
    
    lazy var availableBalanceLabel = UILabel(text: "Available", textColor: .h5887ff)
        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    lazy var fromWalletView = SwapTokenItemView(forAutoLayout: ())
    lazy var toWalletView = SwapTokenItemView(forAutoLayout: ())
    
    lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
        .onTap(self, action: #selector(buttonReverseDidTouch))
    
    lazy var errorLabel = UILabel(textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
        .onTap(self, action: #selector(buttonSwapDidTouch))
    
    init(fromWallet: Wallet? = nil, toWallet: Wallet? = nil) {
        super.init(nibName: nil, bundle: nil)
        defer {
            if let fromWallet = fromWallet {
                self.fromWallet.accept(fromWallet)
            }
            
            if let toWallet = toWallet {
                self.toWallet.accept(toWallet)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        // Set up ui
        view.backgroundColor = .vcBackground
        title = L10n.swap
        
        // set up stackView
        stackView.spacing = 30
        stackView.constraintToSuperviewWithAttribute(.leading)?.constant = 16
        stackView.constraintToSuperviewWithAttribute(.trailing)?.constant = -16
        stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -20
        
        let reverseView: UIView = {
            let view = UIView(forAutoLayout: ())
            let separator = UIView.separator(height: 1, color: .separator)
            view.addSubview(separator)
            separator.autoPinEdge(toSuperviewEdge: .leading)
            separator.autoPinEdge(toSuperviewEdge: .trailing)
            separator.autoAlignAxis(toSuperviewAxis: .horizontal)
            
            view.addSubview(reverseButton)
            reverseButton.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
            
            return view
        }()
        
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.from),
                availableBalanceLabel
            ]),
            fromWalletView,
            BEStackViewSpacing(8),
            reverseView,
            BEStackViewSpacing(8),
            UILabel(text: L10n.to),
            toWalletView,
            UIView.separator(height: 1, color: .separator),
            errorLabel,
            swapButton
        ])
        
        // set up textfields
        fromWalletView.amountTextField.delegate = self
        if fromWallet.value != nil {
            fromWalletView.amountTextField.becomeFirstResponder()
        }
        
        // disable editing in toWallet text field
        toWalletView.amountTextField.isUserInteractionEnabled = false
    }
    
    override func bind() {
        super.bind()
        fromWallet
            .subscribe(onNext: { wallet in
                self.fromWalletView.setUp(wallet: wallet)
                
                if let wallet = wallet {
                    self.availableBalanceLabel.text = "\(L10n.available): \(wallet.amount.toString(maximumFractionDigits: 9)) \(wallet.symbol)"
                } else {
                    self.availableBalanceLabel.text = nil
                }
            })
            .disposed(by: disposeBag)
        
        toWallet
            .subscribe(onNext: { wallet in
                self.toWalletView.setUp(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(fromWallet, toWallet)
            .flatMap {(fromWallet, toWallet) in
                self.viewModel.findSwapPair(fromWallet: fromWallet!, toWallet: toWallet!)
            }
            .subscribe(onNext: { (pair) in
                if pair == nil && (self.fromWallet.value != nil && self.toWallet.value != nil) {
                    // error
                    self.errorLabel.text = L10n.swappingFromToIsCurrentlyUnsupported(self.fromWallet.value!.name, self.toWallet.value!.name)
                } else {
                    // normal
                    self.errorLabel.text = nil
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func buttonUseAllBalanceDidTouch() {
        guard let token = fromWallet.value?.amount else {return}
        fromWalletView.amountTextField.text = token.toString(maximumFractionDigits: 9)
        fromWalletView.amountTextField.sendActions(for: .valueChanged)
    }
    
    @objc func buttonReverseDidTouch() {
        
    }
    
    @objc func buttonSwapDidTouch() {
        
    }
}

extension _SwapTokenVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
