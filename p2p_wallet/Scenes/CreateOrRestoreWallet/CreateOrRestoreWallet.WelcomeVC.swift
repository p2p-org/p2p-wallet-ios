//
//  CreateOrRestoreWallet.WelcomeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import BEPureLayout
import Foundation
import UIKit

extension CreateOrRestoreWallet {
    class WelcomeVC: BEPagesVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .embeded
        }

        override func setUp() {
            super.setUp()
            view.backgroundColor = .clear
            viewControllers = [
                SlideVC(
                    title: L10n.p2PWallet,
                    description: L10n.simpleDecentralizedFinanceForEveryone,
                    replacingImageWithCustomView: create3dAppIconView()
                ),
                // TODO: - Add later
//                SlideVC(
//                    image: .introSlide2,
//                    title: L10n.allTheWaysToBuy,
//                    description: L10n.buyCryptosWithCreditCardFiatOrApplePay
//                ),
//                SlideVC(
//                    image: .introSlide3,
//                    title: L10n.privateAndSecure,
//                    description: L10n.NobodyCanAccessYourPrivateKeys.yourDataIsFullySafe
//                ),
//                SlideVC(
//                    image: .introSlide4,
//                    title: L10n.noHiddenCosts,
//                    description: L10n.SendBTCETHUSDCWithNoFees.swapBTCWithOnly1
//                )
            ]
            currentPageIndicatorTintColor = .h5887ff
            pageIndicatorTintColor = .d1d1d6
        }

        override func setUpPageControl() {
            view.addSubview(pageControl)
            pageControl.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 30.adaptiveHeight)
            pageControl.autoAlignAxis(toSuperviewAxis: .vertical)

            // TODO: - Remove later
            pageControl.isHidden = true
        }

        private func create3dAppIconView() -> UIView {
            let imageView = UIImageView(image: .walletsIcon3d)
            imageView.autoAdjustWidthHeightRatio(375 / 349.35)
            let iconView = imageView.centered(.horizontal)

            let backView = BERoundedCornerShadowView(
                shadowColor: .textBlack.withAlphaComponent(0.05),
                radius: 32,
                offset: .init(width: 0, height: 9),
                opacity: 1,
                cornerRadius: 12.5
            )
            backView.backgroundColor = .background
            backView.autoAdjustWidthHeightRatio(241.16 / 306.53)
            iconView.addSubview(backView)
            backView.autoPinEdge(toSuperviewEdge: .top, withInset: 24.53)
            backView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18.3)
            backView.autoAlignAxis(toSuperviewAxis: .vertical)

            iconView.bringSubviewToFront(imageView)

            return iconView
        }
    }
}

private class SlideVC: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .embeded
    }

    private let contentView: UIView
    init(
        image: UIImage? = nil,
        title: String,
        description: String? = nil,
        replacingImageWithCustomView customView: UIView? = nil
    ) {
        contentView = .ilustrationView(
            image: image,
            title: title,
            description: description,
            replacingImageWithCustomView: customView
        )
        super.init()
    }

    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear

        view.addSubview(contentView)
        contentView.autoPinEdge(toSuperviewSafeArea: .top)
        contentView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 20)
        contentView.autoPinEdge(toSuperviewSafeArea: .trailing, withInset: 20)
        contentView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 55)
    }
}
