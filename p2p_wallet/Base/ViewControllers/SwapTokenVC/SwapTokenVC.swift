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
    
    init(from fromWallet: Wallet? = nil, to toWallet: Wallet? = nil) {
        let vc = _SwapTokenVC(from: fromWallet, to: toWallet)
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
    var sourceWallet = BehaviorRelay<Wallet?>(value: nil)
    var destinationWallet = BehaviorRelay<Wallet?>(value: nil)
    
    lazy var availableBalanceLabel = UILabel(text: "Available", textColor: .h5887ff)
        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    lazy var sourceWalletView = SwapTokenItemView(forAutoLayout: ())
    lazy var destinationWalletView = SwapTokenItemView(forAutoLayout: ())
    
    lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
        .onTap(self, action: #selector(buttonReverseDidTouch))
    
    lazy var errorLabel = UILabel(textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
        .onTap(self, action: #selector(buttonSwapDidTouch))
    
    init(from fromWallet: Wallet? = nil, to toWallet: Wallet? = nil) {
        super.init(nibName: nil, bundle: nil)
        defer {
            if let fromWallet = fromWallet {
                self.sourceWallet.accept(fromWallet)
            }
            
            if let toWallet = toWallet {
                self.destinationWallet.accept(toWallet)
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
            sourceWalletView,
            BEStackViewSpacing(8),
            reverseView,
            BEStackViewSpacing(8),
            UILabel(text: L10n.to),
            destinationWalletView,
            UIView.separator(height: 1, color: .separator),
            errorLabel,
            swapButton
        ])
        
        // set up textfields
        sourceWalletView.amountTextField.delegate = self
        if sourceWallet.value != nil {
            sourceWalletView.amountTextField.becomeFirstResponder()
        }
        
        // disable editing in toWallet text field
        destinationWalletView.amountTextField.isUserInteractionEnabled = false
        
        // setup actions
        sourceWalletView.iconImageView
            .onTap(self, action: #selector(buttonChooseSourceWalletDidTouch))
        
        destinationWalletView.iconImageView
            .onTap(self, action: #selector(buttonChooseDestinationWalletDidTouch))
    }
    
    override func bind() {
        super.bind()
        sourceWallet
            .subscribe(onNext: { wallet in
                self.sourceWalletView.setUp(wallet: wallet)
                
                if let wallet = wallet {
                    self.availableBalanceLabel.text = "\(L10n.available): \(wallet.amount.toString(maximumFractionDigits: 9)) \(wallet.symbol)"
                } else {
                    self.availableBalanceLabel.text = nil
                }
            })
            .disposed(by: disposeBag)
        
        destinationWallet
            .subscribe(onNext: { wallet in
                self.destinationWalletView.setUp(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
//        Observable.combineLatest(sourceWallet, destinationWallet)
//            .flatMap {(fromWallet, toWallet) in
//                self.viewModel.findSwapPair(fromWallet: fromWallet, toWallet: toWallet)
//            }
//            .subscribe(onNext: { (pair) in
//                if pair == nil && (self.sourceWallet.value != nil && self.destinationWallet.value != nil) {
//                    // error
//                    self.errorLabel.text = L10n.swappingFromToIsCurrentlyUnsupported(self.sourceWallet.value!.name, self.destinationWallet.value!.name)
//                } else {
//                    // normal
//                    self.errorLabel.text = nil
//                }
//            })
//            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func buttonUseAllBalanceDidTouch() {
        guard let token = sourceWallet.value?.amount else {return}
        sourceWalletView.amountTextField.text = token.toString(maximumFractionDigits: 9)
        sourceWalletView.amountTextField.sendActions(for: .valueChanged)
    }
    
    @objc func buttonChooseSourceWalletDidTouch() {
        let vc = ChooseWalletVC()
        vc.customFilter = {
            $0.amount > 0 && $0.symbol != self.destinationWallet.value?.symbol
        }
        vc.completion = {wallet in
            let wallet = self.viewModel.walletsVM.items.first(where: {$0.pubkey == wallet.pubkey})
            self.sourceWallet.accept(wallet)
            vc.back()
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func buttonChooseDestinationWalletDidTouch() {
        let vc = ChooseWalletVC()
        vc.customFilter = {
            $0.symbol != self.sourceWallet.value?.symbol
        }
        vc.completion = {wallet in
            let wallet = self.viewModel.walletsVM.items.first(where: {$0.pubkey == wallet.pubkey})
            self.destinationWallet.accept(wallet)
            vc.back()
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func buttonReverseDidTouch() {
        let tempWallet = sourceWallet.value
        sourceWallet.accept(destinationWallet.value)
        destinationWallet.accept(tempWallet)
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
