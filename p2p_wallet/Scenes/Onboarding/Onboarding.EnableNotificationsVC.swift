//
//  Onboarding.EnableNotificationsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import AnalyticsManager
import BEPureLayout
import Foundation
import Resolver
import UIKit

extension Onboarding {
    class EnableNotificationsVC: BaseVC {
        @Injected private var analyticsManager: AnalyticsManager

        // MARK: - Dependencies

        private let viewModel: OnboardingViewModelType

        // MARK: - Initializer

        init(viewModel: OnboardingViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()
            // navigation bar
            navigationItem.hidesBackButton = true
            navigationItem.title = L10n.letSStayInTouch
            let skipButton = UIBarButtonItem(
                title: L10n.skip.uppercaseFirst,
                style: .plain,
                target: self,
                action: #selector(buttonSkipDidTouch)
            )
            navigationItem.rightBarButtonItem = skipButton
            skipButton.setTitleTextAttributes([.foregroundColor: UIColor.h5887ff], for: .normal)

            // explanation view
            let explanationView = UILabel(
                text: L10n.allowPushNotificationsSoYouDonTMissAnyImportantUpdatesOnYourAccount,
                textSize: 15,
                textColor: .black,
                numberOfLines: 0
            )
                .padding(.init(all: 18), backgroundColor: .fafafc, cornerRadius: 12)
            view.addSubview(explanationView)
            explanationView.autoPinEdge(toSuperviewSafeArea: .top, withInset: 18)
            explanationView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 18)
            explanationView.autoPinEdge(toSuperviewSafeArea: .trailing, withInset: 18)

            // collection
            let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .init(x: 0, y: 20))
            view.addSubview(scrollView)
            scrollView.autoPinEdge(.top, to: .bottom, of: explanationView)
            scrollView.autoPinEdge(toSuperviewEdge: .leading, withInset: 18)
            scrollView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 18)

            // button
            let allowButton = WLStepButton.main(
                image: .notificationsButtonSmall,
                text: L10n.allowNotifications
            )
                .onTap(self, action: #selector(buttonAllowDidTouch))
            view.addSubview(allowButton)
            allowButton.autoPinEdgesToSuperviewSafeArea(with: .init(all: 18), excludingEdge: .top)
            allowButton.autoPinEdge(.top, to: .bottom, of: scrollView)

            // items
            let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                createCell(
                    image: .appIconSmall,
                    title: L10n.newStakingOptionAvailable,
                    subtitle: L10n.getUpTo8APYOnStakingUSDC,
                    timeLabelText: L10n.justNow
                )
                createCell(
                    image: .renbtcPlaceholder,
                    subimage: .appIconSmall,
                    title: L10n.receivedRenBTC(0.01),
                    subtitle: L10n.from + " bc1qa5wkgaew2dk...9hz6",
                    timeLabelText: L10n.mAgo(2)
                )
                createCell(
                    image: .ethPlaceholder,
                    subimage: .appIconSmall,
                    title: L10n.successfullySent("1.2 ETH"),
                    subtitle: L10n.to + " 0xc377814e01DB2ed4...f1cB",
                    timeLabelText: L10n.mAgo(6)
                )
                createCell(
                    image: .swapPlaceholder,
                    subimage: .appIconSmall,
                    title: L10n.received("1.23 SOL"),
                    subtitle: L10n.swappedSuccessfully("USDC", "SOL"),
                    timeLabelText: L10n.hAgo(1)
                )
            }
            scrollView.contentView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }

        @objc private func buttonAllowDidTouch() {
            analyticsManager.log(event: .pushApproved(lastScreen: "Onboarding"))
            viewModel.requestRemoteNotifications()
        }

        @objc private func buttonSkipDidTouch() {
            analyticsManager.log(event: .pushRejected)
            viewModel.markNotificationsAsSet()
        }

        private func createCell(
            image: UIImage,
            subimage: UIImage? = nil,
            title: String,
            subtitle: String,
            timeLabelText: String?
        ) -> UIView {
            let view = BERoundedCornerShadowView(
                shadowColor: .textBlack.withAlphaComponent(0.05),
                radius: 8,
                offset: .init(width: 0, height: 1),
                opacity: 1,
                cornerRadius: 16,
                contentInset: .init(all: 10)
            )
            view.stackView.axis = .horizontal
            view.stackView.spacing = 10
            view.stackView.alignment = .center
            let imageView = UIImageView(width: 40, height: 40, cornerRadius: 10, image: image)
            view.stackView.addArrangedSubviews {
                imageView
                UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill) {
                        UILabel(text: title, textSize: 13, weight: .semibold, numberOfLines: 0)
                        UILabel(text: timeLabelText, textSize: 13, textColor: .textSecondary, textAlignment: .right)
                    }

                    UILabel(text: subtitle, textSize: 13, numberOfLines: 0)
                }
            }
            if let subimage = subimage {
                let subImageView = UIImageView(width: 16, height: 16, cornerRadius: 2, image: subimage)
                view.addSubview(subImageView)
                subImageView.autoPinEdge(.trailing, to: .trailing, of: imageView, withOffset: 5.33)
                subImageView.autoPinEdge(.bottom, to: .bottom, of: imageView, withOffset: 1.33)
            }
            return view
        }
    }
}
