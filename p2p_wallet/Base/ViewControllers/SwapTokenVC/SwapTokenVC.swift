//
//  SwapTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import RxSwift
import RxCocoa
import Action

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
            self.viewModel.sourceWallet.accept(fromWallet ?? viewModel.walletsVM.items.first(where: {$0.symbol == "SOL"}))
            self.viewModel.destinationWallet.accept(toWallet)
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
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.minimumReceive + ": "),
                UILabel(text: L10n.minimumReceive),
            ]),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.fee + ": "),
                UILabel(text: L10n.minimumReceive),
            ]),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.slippage + ": "),
                UILabel(text: L10n.minimumReceive),
            ]),
            errorLabel,
            swapButton
        ])
        
        // setup actions
        sourceWalletView.chooseTokenAction = CocoaAction {
            let vc = ChooseWalletVC()
            vc.completion = {wallet in
                let wallet = self.viewModel.walletsVM.items.first(where: {$0.pubkey == wallet.pubkey})
                self.viewModel.sourceWallet.accept(wallet)
                self.sourceWalletView.amountTextField.becomeFirstResponder()
                vc.back()
            }
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
        
        destinationWalletView.chooseTokenAction = CocoaAction {
            let vc = ChooseWalletVC()
            vc.customFilter = {_ in true}
            vc.completion = {wallet in
                let wallet = self.viewModel.walletsVM.items.first(where: {$0.pubkey == wallet.pubkey})
                self.viewModel.destinationWallet.accept(wallet)
                vc.back()
            }
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
        
        // set up textfields
        sourceWalletView.amountTextField.delegate = self
        sourceWalletView.amountTextField.becomeFirstResponder()
        
        // disable editing in toWallet text field
        destinationWalletView.amountTextField.isUserInteractionEnabled = false
        destinationWalletView.equityValueLabel.isHidden = true
    }
    
    override func bind() {
        super.bind()
        Observable.combineLatest(viewModel.sourceWallet, viewModel.destinationWallet)
            .subscribe(onNext: { (sourceWallet, destinationWallet) in
                // configure source wallet
                self.sourceWalletView.setUp(wallet: sourceWallet)
                
                if let wallet = sourceWallet {
                    self.availableBalanceLabel.text = "\(L10n.available): \(wallet.amount.toString(maximumFractionDigits: 9)) \(wallet.symbol)"
                } else {
                    self.availableBalanceLabel.text = nil
                }
                
                // configure destinationWallet
                self.destinationWalletView.setUp(wallet: destinationWallet)
                
                // swap pair
                let pair = self.viewModel.findSwapPair(fromWallet: sourceWallet, toWallet: destinationWallet)
                var errorText: String?
                
                if let sourceWallet = sourceWallet,
                   let destinationWallet = destinationWallet
                {
                    if sourceWallet.symbol == destinationWallet.symbol {
                        errorText = L10n.YouCanNotSwapToItself.pleaseChooseAnotherToken(sourceWallet.symbol)
                    } else if pair == nil && self.viewModel.availableSwapPairs.count > 0 {
                        errorText = L10n.swappingFromToIsCurrentlyUnsupported(self.viewModel.sourceWallet.value!.symbol, self.viewModel.destinationWallet.value!.symbol)
                    }
                }
                
                self.errorLabel.text = errorText
                self.errorLabel.isHidden = errorText == nil
            })
            .disposed(by: disposeBag)
        
        sourceWalletView.amountTextField.rx.text
            .map {$0?.double ?? 0}
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .flatMapLatest {[weak self] (value) -> Single<UInt64?> in
                guard value != 0,
                      let pool = self?.viewModel.currentSwapPair?.pool,
                      let slippage = self?.viewModel.slippage.value,
                      let decimals = self?.viewModel.sourceWallet.value?.decimals
                else {return .just(nil)}
                return SolanaSDK.shared.getEstimatedAmount(pool: pool, slippage: slippage, inputAmount: UInt64(value * pow(10, Double(decimals))))
                    .map {$0}
            }
            .map {[weak self] value -> Double? in
                guard let value = value,
                      let decimals = self?.viewModel.destinationWallet.value?.decimals
                else {return nil}
                return Double(value) * pow(10, -Double(decimals))
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { value in
                self.destinationWalletView.amountTextField.text = value?.toString(maximumFractionDigits: 9)
                self.destinationWalletView.amountTextField.sendActions(for: .valueChanged)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func buttonUseAllBalanceDidTouch() {
        guard let token = viewModel.sourceWallet.value?.amount else {return}
        sourceWalletView.amountTextField.text = token.toString(maximumFractionDigits: 9)
        sourceWalletView.amountTextField.sendActions(for: .valueChanged)
    }
    
    @objc func buttonReverseDidTouch() {
        let tempWallet = viewModel.sourceWallet.value
        viewModel.sourceWallet.accept(viewModel.destinationWallet.value)
        viewModel.destinationWallet.accept(tempWallet)
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
