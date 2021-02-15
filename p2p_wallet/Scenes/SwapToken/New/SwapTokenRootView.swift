//
//  SwapTokenRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import UIKit
import RxSwift
import Action

class SwapTokenRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: SwapTokenViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    lazy var availableSourceBalanceLabel = UILabel(text: "Available", textColor: .h5887ff)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.useAllBalance))
    lazy var destinationBalanceLabel = UILabel(textColor: .textSecondary)
    lazy var sourceWalletView = SwapTokenItemView(forAutoLayout: ())
    lazy var destinationWalletView = SwapTokenItemView(forAutoLayout: ())
    
    lazy var exchangeRateLabel = UILabel(text: nil)
    lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.reverseExchangeRate))
    
    lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.swapSourceAndDestination))
    
    lazy var minimumReceiveLabel = UILabel(text: nil)
    lazy var feeLabel = UILabel(text: nil)
    lazy var slippageLabel = UILabel(text: nil)
    
    lazy var errorLabel = UILabel(textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.swap))
    
    // MARK: - Initializers
    init(viewModel: SwapTokenViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        backgroundColor = .vcBackground
        layout()
        bind()
        
        // setup actions
        sourceWalletView.chooseTokenAction = CocoaAction {
            self.viewModel.chooseSourceWallet()
            return .just(())
        }
        
        destinationWalletView.chooseTokenAction = CocoaAction {
            self.viewModel.chooseDestinationWallet()
            return .just(())
        }
        
        // set up textfields
        sourceWalletView.amountTextField.delegate = self
        sourceWalletView.amountTextField.becomeFirstResponder()
        
        // disable editing in toWallet text field
        destinationWalletView.amountTextField.isUserInteractionEnabled = false
        destinationWalletView.equityValueLabel.isHidden = true
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
    }
    
    // MARK: - Layout
    private func layout() {
        stackView.spacing = 30
        
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.from),
                availableSourceBalanceLabel
            ]),
            sourceWalletView,
            BEStackViewSpacing(8),
            swapSourceAndDestinationView(),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.to),
                destinationBalanceLabel
            ]),
            destinationWalletView,
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.exchangeRate + ": "),
                exchangeRateLabel
                    .withContentHuggingPriority(.required, for: .horizontal),
                exchangeRateReverseButton
            ])
                .padding(.init(all: 8), backgroundColor: .f6f6f8, cornerRadius: 12),
            UIView.separator(height: 1, color: .separator),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.minimumReceive + ": "),
                minimumReceiveLabel
            ]),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.fee + ": "),
                feeLabel
            ]),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.slippage + ": "),
                slippageLabel
            ])
            .onTap(viewModel, action: #selector(SwapTokenViewModel.chooseSlippage)),
            errorLabel,
            swapButton
        ])
    }
    
    private func bind() {
        // pool validation
        viewModel.pools.observable
            .subscribe(onNext: {[weak self] state in
                self?.removeErrorView()
                self?.hideHud()
                self?.stackView.isHidden = true
                switch state {
                case .initializing, .loading:
                    self?.showIndetermineHudWithMessage(L10n.loading)
                case .loaded:
                    self?.stackView.isHidden = false
                    if self?.viewModel.pools.value?.isEmpty == true {
                        self?.showErrorView(title: L10n.swappingIsCurrentlyUnavailable, description: L10n.swappingPoolsNotFound + "\n" + L10n.pleaseTryAgainLater)
                    }
                case .error(let error):
                    self?.showErrorView(error: error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func swapSourceAndDestinationView() -> UIView {
        let view = UIView(forAutoLayout: ())
        let separator = UIView.separator(height: 1, color: .separator)
        view.addSubview(separator)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        separator.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        view.addSubview(reverseButton)
        reverseButton.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
        
        return view
    }
}

extension SwapTokenRootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
