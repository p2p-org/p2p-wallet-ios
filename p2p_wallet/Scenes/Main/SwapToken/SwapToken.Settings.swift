//
//  SwapToken.Settings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/08/2021.
//

import Foundation

extension SwapToken {
    // MARK: - View controllers
    class SettingsViewController: SettingsBaseViewController {
        // MARK: - Properties
        private let viewModel: ViewModel
        
        // MARK: - Subviews
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
        }
        
        override func setUpContent(stackView: UIStackView) {
            stackView.spacing = 12
            stackView.addArrangedSubviews {
                createSectionView(
                    title: L10n.slippageSettings,
                    contentView: slippageLabel,
                    addSeparatorOnTop: false
                )
                
                createSectionView(
                    title: L10n.payNetworkFeeWith,
                    contentView: payingTokenLabel
                )
            }
        }
    }
    
    // MARK: - Helpers
    class SettingsBaseViewController: WLIndicatorModalVC {
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
        
        lazy var stackView = UIStackView(axis: .horizontal, spacing: 20, alignment: .fill, distribution: .fill) {
            headerView
            contentStackView
                .padding(.init(all: 20))
        }
        
        private lazy var contentStackView = UIStackView(axis: .horizontal, spacing: 20, alignment: .fill, distribution: .fill)
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
            stackView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 20)
            
            setUpContent(stackView: contentStackView)
        }
        
        func setUpContent(stackView: UIStackView) {
            
        }
        
        func hideBackButton(_ isHidden: Bool = true) {
            backButton.isHidden = isHidden
        }
        
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            orientationDidChangeTo(UIDevice.current.orientation)
        }
        
        func orientationDidChangeTo(_ orientation: UIDeviceOrientation) {
            if orientation.isLandscape {
                contentStackView.axis = .horizontal
            } else {
                contentStackView.axis = .vertical
            }
        }
        
        // MARK: - Transition
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            view.fittingHeight(targetWidth: targetWidth) + view.safeAreaInsets.bottom
        }
    }
}
