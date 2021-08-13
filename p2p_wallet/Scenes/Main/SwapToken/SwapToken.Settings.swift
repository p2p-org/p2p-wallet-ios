//
//  SwapToken.Settings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension SwapToken {
    // MARK: - View controllers
    class SettingsNavigationController: BENavigationController, CustomPresentableViewController {
        var transitionManager: UIViewControllerTransitioningDelegate?
        
        func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            (topViewController as? SettingsBaseViewController)?
                .calculateFittingHeightForPresentedView(targetWidth: targetWidth)
                ?? .infinity
        }
        
        override func pushViewController(_ viewController: UIViewController, animated: Bool) {
            super.pushViewController(viewController, animated: animated)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updatePresentationLayout(animated: animated)
            }
        }
        
        override func popViewController(animated: Bool) -> UIViewController? {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updatePresentationLayout(animated: animated)
            }
            return super.popViewController(animated: animated)
        }
    }
    class SettingsViewController: SettingsBaseViewController {
        // MARK: - Properties
        private let viewModel: ViewModel
        private var defaultsDisposables = [DefaultsDisposable]()
        private let payingTokenSubject = BehaviorRelay<PayingToken>(value: Defaults.payingToken)
        
        // MARK: - Subviews
        private lazy var separator = UIView.defaultSeparator()
        private var payingTokenSection: UIView?
        private lazy var slippageLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var payingTokenLabel = UILabel(textSize: 15, weight: .medium)
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            title = L10n.swapSettings
            hideBackButton()
        }
        
        override func bind() {
            super.bind()
            viewModel.output.slippage
                .map {slippageAttributedText(slippage: $0)}
                .drive(slippageLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            defaultsDisposables.append(Defaults.observe(\.payingToken, handler: { [weak self] update in
                self?.payingTokenSubject.accept(update.newValue ?? .transactionToken)
            }))
            
            Driver.combineLatest(
                viewModel.output.sourceWallet,
                viewModel.output.destinationWallet,
                payingTokenSubject.asDriver()
            )
                .drive(onNext: {[weak self] source, destination, payingToken in
                    self?.setUpPayingTokenLabel(source: source, destination: destination, payingToken: payingToken)
                })
                .disposed(by: disposeBag)
                
        }
        
        override func setUpContent(stackView: UIStackView) {
            stackView.spacing = 12
            
            payingTokenSection = createSectionView(
                title: L10n.payNetworkFeeWith,
                contentView: payingTokenLabel,
                addSeparatorOnTop: false
            )
            
            stackView.addArrangedSubviews {
                createSectionView(
                    title: L10n.slippageSettings,
                    contentView: slippageLabel,
                    addSeparatorOnTop: false
                )
                    .withTag(1)
                
                separator
                
                payingTokenSection!
            }
        }
        
        // MARK: - Helper
        private func setUpPayingTokenLabel(
            source: Wallet?,
            destination: Wallet?,
            payingToken: PayingToken
        ) {
            let text: String
            var isChoosingEnabled = true
            // if source or destination is native wallet
            if source == nil && destination == nil {
                text = payingToken == .nativeSOL ? "SOL": L10n.transactionToken
            } else if source?.token.isNative == true || destination?.token.isNative == true || payingToken == .nativeSOL
            {
                text = "SOL"
                isChoosingEnabled = false
            } else if let source = source, let destination = destination {
                text = "\(source.token.symbol) + \(destination.token.symbol)"
            } else {
                text = L10n.transactionToken
            }
            payingTokenLabel.text = text
            payingTokenSection?.isUserInteractionEnabled = isChoosingEnabled
        }
    }
    
    // MARK: - Helpers
    class SettingsBaseViewController: WLIndicatorModalVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
        
        // MARK: - Properties
        override var title: String? {
            didSet {
                titleLabel.text = title
            }
        }
        
        // MARK: - Subviews
        private lazy var titleLabel = UILabel(text: L10n.swapSettings, textSize: 17, weight: .semibold)
        private lazy var backButton = UIImageView(width: 10.72, height: 17.52, image: .backArrow, tintColor: .textBlack)
            .padding(.init(x: 6, y: 0))
            .onTap(self, action: #selector(back))
        
        lazy var headerView: UIView = {
            let headerView = UIView(forAutoLayout: ())
            let stackView = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                backButton
                titleLabel
            }
            headerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 20))
            let separator = UIView.defaultSeparator()
            headerView.addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .init(all: 0), excludingEdge: .top)
            return headerView
        }()
        
        lazy var stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
            headerView
            
            contentStackView
                .padding(.init(top: 0, left: 20, bottom: 20, right: 20))
        }
        
        lazy var contentStackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill)
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            containerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            stackView.autoPinEdge(toSuperviewSafeArea: .bottom)
            
            setUpContent(stackView: contentStackView)
        }
        
        func setUpContent(stackView: UIStackView) {
            
        }
        
        func hideBackButton(_ isHidden: Bool = true) {
            backButton.isHidden = isHidden
        }
        
        // MARK: - Transition
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) +
                containerView.fittingHeight(targetWidth: targetWidth) +
                view.safeAreaInsets.bottom
        }
    }
}
