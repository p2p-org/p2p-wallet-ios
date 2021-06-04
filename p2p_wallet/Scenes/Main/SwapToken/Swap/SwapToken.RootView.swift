//
//  SwapToken.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2021.
//

import UIKit
import RxSwift
import Action

extension SwapToken {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ViewModel
        
        // MARK: - Subviews
        lazy var availableSourceBalanceLabel = UILabel(text: "Available", weight: .medium, textColor: .h5887ff)
            .onTap(viewModel, action: #selector(ViewModel.useAllBalance))
        lazy var destinationBalanceLabel = UILabel(weight: .medium, textColor: .textSecondary)
        lazy var sourceWalletView = SwapToken.WalletView(forAutoLayout: ())
        lazy var destinationWalletView = SwapToken.WalletView(forAutoLayout: ())
        
        lazy var exchangeRateLabel = UILabel(text: nil)
        lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
            .onTap(viewModel, action: #selector(ViewModel.reverseExchangeRate))
        
        lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
            .onTap(viewModel, action: #selector(ViewModel.swapSourceAndDestination))
        
        lazy var minimumReceiveLabel = UILabel(textColor: .textSecondary)
        lazy var feeLabel = UILabel(textColor: .textSecondary)
        lazy var slippageLabel = UILabel(textColor: .textSecondary)
        
        lazy var errorLabel = UILabel(textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
        
        lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
            .onTap(viewModel, action: #selector(ViewModel.authenticateAndSwap))
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
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
            sourceWalletView.chooseTokenAction = CocoaAction { [weak self] in
                self?.viewModel.chooseSourceWallet()
                return .just(())
            }
            
            destinationWalletView.chooseTokenAction = CocoaAction { [weak self] in
                self?.viewModel.chooseDestinationWallet()
                return .just(())
            }
            
            // set up textfields
            sourceWalletView.amountTextField.delegate = self
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
        }
        
        // MARK: - Layout
        private func layout() {
            stackView.spacing = 30
            
            stackView.addArrangedSubviews([
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    UILabel(text: L10n.from, weight: .semibold),
                    availableSourceBalanceLabel
                ]),
                sourceWalletView,
                BEStackViewSpacing(8),
                swapSourceAndDestinationView(),
                BEStackViewSpacing(8),
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    UILabel(text: L10n.to, weight: .semibold),
                    destinationBalanceLabel
                ]),
                destinationWalletView,
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    UILabel(text: L10n.price + ": ", weight: .medium, textColor: .textSecondary),
                    exchangeRateLabel
                        .withContentHuggingPriority(.required, for: .horizontal),
                    exchangeRateReverseButton
                ])
                    .padding(.init(all: 8), backgroundColor: .f6f6f8, cornerRadius: 12),
                UIView.separator(height: 1, color: .separator),
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                    UILabel(text: L10n.minimumReceive + ": ", textColor: .textSecondary),
                    minimumReceiveLabel
                ]),
                BEStackViewSpacing(16),
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                    UILabel(text: L10n.fee + ": ", textColor: .textSecondary),
                    feeLabel
                ]),
                BEStackViewSpacing(16),
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                    UILabel(text: L10n.slippage + ": ", textColor: .textSecondary),
                    slippageLabel
                ])
                .onTap(viewModel, action: #selector(ViewModel.chooseSlippage)),
                errorLabel,
                BEStackViewSpacing(16),
                swapButton,
                BEStackViewSpacing(12),
                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill, arrangedSubviews: [
                    UILabel(text: L10n.poweredBy, textSize: 13, textColor: .textSecondary, textAlignment: .center),
                    UIImageView(width: 94, height: 24, image: .orcaLogo)
                ])
                    .centeredHorizontallyView
            ])
        }
        
        private func bind() {
            // error
            viewModel.output.
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
}

// MARK: - TextField delegate
extension SwapToken.RootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
