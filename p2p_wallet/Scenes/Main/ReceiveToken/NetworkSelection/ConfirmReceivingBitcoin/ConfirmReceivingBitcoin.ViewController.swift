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

        let viewModel: ConfirmReceivingBitcoinViewModelType

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
                        viewModel.accountStatusDriver
                            .map { $0 != .payingWalletAvailable }
                            .drive(label.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                // Additional spacer in top up view
                UIView.spacer
                    .setup { view in
                        view.autoSetDimension(.height, toSize: 14)
                        viewModel.accountStatusDriver
                            .map { $0 != .topUpRequired }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                // Alert and separator
                UIView()
                    .setup { view in
                        let separator = UIView.defaultSeparator()
                        view.addSubview(separator)
                        separator.autoAlignAxis(toSuperviewAxis: .horizontal)
                        separator.autoPinEdge(toSuperviewEdge: .leading)
                        separator.autoPinEdge(toSuperviewEdge: .trailing)

                        let imageView = UIImageView(width: 44, height: 44, image: .squircleAlert)
                        view.addSubview(imageView)
                        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
                        imageView.autoPinEdge(toSuperviewEdge: .top)
                        imageView.autoPinEdge(toSuperviewEdge: .bottom)
                    }
                    .padding(.init(only: .bottom, inset: 18))

                // Descripton label
                contentView()
                    .padding(.init(top: 0, left: 18, bottom: 36, right: 18))

                // Button stack view
                BEVStack(spacing: 10) {
                    topUpButtonsView()
                        .setup { view in
                            viewModel.accountStatusDriver
                                .map { $0 != .topUpRequired }
                                .drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                        }

                    shareSolanaAddressButton()
                        .setup { view in
                            viewModel.accountStatusDriver
                                .map { $0 != .topUpRequired }
                                .drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                        }

                    createRenBTCButton()
                        .setup { view in
                            viewModel.accountStatusDriver
                                .map { $0 != .payingWalletAvailable }
                                .drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                        }
                }
                .padding(.init(top: 0, left: 18, bottom: 18, right: 18))
            }
        }

        func contentView() -> UIView {
            BEVStack(spacing: 12) {
                topUpRequiredView()
                    .setup { view in
                        viewModel.accountStatusDriver
                            .map { $0 != .topUpRequired }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                createRenBTCView()
                    .setup { view in
                        viewModel.accountStatusDriver
                            .map { $0 != .payingWalletAvailable }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }
            }
        }

        // MARK: - Binding

        override func bind() {
            super.bind()
            viewModel.isLoadingDriver
                .drive(onNext: { [weak self] isLoading in
                    isLoading ? self?.showIndetermineHud() : self?.hideHud()
                })
                .disposed(by: disposeBag)

            viewModel.accountStatusDriver
                .drive(onNext: { [weak self] _ in
                    self?.updatePresentationLayout(animated: true)
                })
                .disposed(by: disposeBag)

            viewModel.errorDriver
                .drive(onNext: { [weak self] error in
                    if error != nil {
                        self?.showErrorView(retryAction: .init { [weak self] in
                            self?.viewModel.reload()
                            return .just(())
                        })
                    }
                })
                .disposed(by: disposeBag)

            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case let .chooseWallet(selectedWallet, payableWallets):
                let vm = ChooseWallet.ViewModel(
                    selectedWallet: selectedWallet,
                    handler: viewModel,
                    staticWallets: payableWallets,
                    showOtherWallets: false
                )
                let vc = ChooseWallet.ViewController(title: L10n.chooseWallet, viewModel: vm)
                present(vc, animated: true)
            default:
                break
            }
        }
    }
}
