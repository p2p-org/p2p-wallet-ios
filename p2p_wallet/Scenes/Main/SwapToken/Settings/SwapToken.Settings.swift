//
//  SwapToken.Settings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/08/2021.
//

import Foundation

extension SerumSwapV1 {
    class SettingsNavigationController: UINavigationController, CustomPresentableViewController {
        var transitionManager: UIViewControllerTransitioningDelegate?
        
        func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            (visibleViewController as? SettingsBaseViewController)?
                .calculateFittingHeightForPresentedView(targetWidth: targetWidth)
                ?? .infinity
        }
    }
    
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
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            updatePresentationLayout(animated: animated)
        }
        
        override func setUp() {
            super.setUp()
            containerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            stackView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
            
            setUpContent(stackView: contentStackView)
            stackView.addArrangedSubview(.spacer)
        }
        
        func setUpContent(stackView: UIStackView) {
            
        }
        
        func hideBackButton(_ isHidden: Bool = true) {
            backButton.isHidden = isHidden
        }
        
        // MARK: - Transition
        func updatePresentationLayout(animated: Bool) {
            (navigationController as? SettingsNavigationController)?.updatePresentationLayout(animated: animated)
        }
        
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) +
                containerView.fittingHeight(targetWidth: targetWidth) -
                view.safeAreaInsets.bottom
        }
    }
}
