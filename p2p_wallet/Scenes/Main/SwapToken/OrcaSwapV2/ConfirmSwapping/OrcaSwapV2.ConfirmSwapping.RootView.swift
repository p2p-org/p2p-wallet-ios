//
//  OrcaSwapV2.ConfirmSwapping.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Foundation
import UIKit

extension OrcaSwapV2.ConfirmSwapping {
    final class RootView: ScrollableVStackRootView {
        // MARK: - Properties
        private let viewModel: OrcaSwapV2ConfirmSwappingViewModelType
        
        // MARK: - Subviews
        private lazy var bannerView = UIView.greyBannerView(axis: .horizontal, spacing: 12, alignment: .top) {
            UILabel(
                text: L10n.BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction
                    .onceConfirmedItCannotBeReversed,
                textSize: 15,
                numberOfLines: 0
            )
            UIView.closeBannerButton()
                .onTap(self, action: #selector(closeBannerButtonDidTouch))
        }
        
        // MARK: - Initializers
        init(viewModel: OrcaSwapV2ConfirmSwappingViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            scrollView.contentInset = .init(top: 8, left: 18, bottom: 18, right: 18)
            setUp()
        }
        
        private func setUp() {
            stackView.addArrangedSubviews {
                UIView.floatingPanel(contentInset: .init(x: 8, y: 16), axis: .horizontal, spacing: 8, alignment: .center, distribution: .equalCentering) {
                    UIImageView(width: 11.88, height: 9.74, image: .arrowForward, tintColor: .h8e8e93)
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .padding(.init(all: 10), backgroundColor: .fafafc, cornerRadius: 12)
                        .withContentHuggingPriority(.required, for: .horizontal)
                }
            }
            
            if !viewModel.isBannerForceClosed() {
                stackView.insertArrangedSubview(bannerView, at: 0)
            }
        }
        
        // MARK: - Action
        @objc private func closeBannerButtonDidTouch() {
            UIView.animate(withDuration: 0.3) {
                self.bannerView.isHidden = true
            }
            viewModel.closeBanner()
        }
    }
}
