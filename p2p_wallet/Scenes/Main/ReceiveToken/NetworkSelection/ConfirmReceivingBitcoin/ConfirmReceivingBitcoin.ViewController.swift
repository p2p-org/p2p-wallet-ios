//
//  ConfirmReceivingBitcoin.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import BEPureLayout
import Foundation
import RxSwift
import UIKit

extension ConfirmReceivingBitcoin {
    class ViewController: WLModalViewController {
        // MARK: - Properties

        private let viewModel: ConfirmReceivingBitcoinViewModelType

        // MARK: - Initializer

        init(viewModel: ConfirmReceivingBitcoinViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - View builder

        override func build() -> UIView {
            BEVStack {
                // Receiving via bitcoin network
                UILabel(
                    text: L10n.receivingViaBitcoinNetwork,
                    textSize: 20,
                    weight: .semibold,
                    numberOfLines: 0,
                    textAlignment: .center
                )
                    .padding(.init(top: 18, left: 18, bottom: 4, right: 18))

                // Make sure you understand the aspect
                UILabel(
                    text: L10n.makeSureYouUnderstandTheseAspects,
                    textSize: 15,
                    textColor: .textSecondary,
                    numberOfLines: 0,
                    textAlignment: .center
                )
                    .padding(.init(top: 0, left: 18, bottom: 18, right: 18))
                    .setup { label in
                        viewModel.outputDriver.map { $0.accountStatus != .payingWalletAvailable }
                            .drive(label.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                // Alert and separator
                UIView()
                    .setup { view in
                        let imageView = UIImageView(width: 44, height: 44, image: .squircleAlert)
                        view.addSubview(imageView)
                        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
                        imageView.autoPinEdge(toSuperviewEdge: .top)
                        imageView.autoPinEdge(toSuperviewEdge: .bottom)

                        let separator = UIView.defaultSeparator()
                        view.addSubview(separator)
                        separator.autoAlignAxis(toSuperviewAxis: .horizontal)
                        separator.autoPinEdge(toSuperviewEdge: .leading)
                        separator.autoPinEdge(toSuperviewEdge: .trailing)
                    }

                // Descripton label
                contentView()
                    .padding(.init(top: 0, left: 18, bottom: 36, right: 18))

                // Button stack view
                buttonsView()
                    .padding(.init(top: 0, left: 18, bottom: 0, right: 18))
            }
        }

        func contentView() -> UIView {
            UILabel(text: "content")
        }

        func buttonsView() -> BEVStack {
            BEVStack(spacing: 10) {}
        }

        // MARK: - Binding

        override func bind() {
            super.bind()
            viewModel.outputDriver.map(\.isLoading)
                .drive(onNext: { [weak self] isLoading in
                    isLoading ? self?.showIndetermineHud() : self?.hideHud()
                })
                .disposed(by: disposeBag)

            viewModel.outputDriver
                .drive(onNext: { [weak self] _ in
                    self?.updatePresentationLayout(animated: true)
                })
                .disposed(by: disposeBag)
        }
    }
}
