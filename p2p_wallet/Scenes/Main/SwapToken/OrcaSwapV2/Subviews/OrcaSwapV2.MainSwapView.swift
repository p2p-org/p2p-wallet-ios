//
//  OrcaSwap2.MainSwapView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.11.2021.
//

import UIKit
import BEPureLayout
import RxSwift
import RxCocoa

extension OrcaSwapV2 {
    final class MainSwapView: WLFloatingPanelView {
        private let fromWalletView: WalletView
        private let switchButton = UIButton(width: 32, height: 32)
        private let toWalletView: WalletView
        private let receiveAtLeastView = HorizontalLabelsWithSpacer()

        private let viewModel: OrcaSwapV2ViewModelType
        private let disposeBag = DisposeBag()

        init(viewModel: OrcaSwapV2ViewModelType) {
            fromWalletView = WalletView(viewModel: viewModel, type: .source)
            toWalletView = WalletView(viewModel: viewModel, type: .destination)
            self.viewModel = viewModel

            super.init(contentInset: .init(all: 18))
        }

        override func commonInit() {
            super.commonInit()

            configureSubviews()
            layout()
            bind()
        }

        private func configureSubviews() {
            configureReceiveAtLeast()

            switchButton.setImage(.swapSwitch, for: .normal)
            switchButton.addTarget(self, action: #selector(switchTapped), for: .touchUpInside)
        }

        private func configureReceiveAtLeast() {
            let configureLabel: (UILabel) -> Void = { label in
                label.font = .systemFont(ofSize: 15, weight: .medium)
                label.textColor = .h8e8e93
            }

            receiveAtLeastView.configureLeftLabel { label in
                configureLabel(label)
                label.text = L10n.colonReceiveAtLeast
            }
            receiveAtLeastView.configureRightLabel(configure: configureLabel)
        }

        private func setAtLeastText(string: String?) {
            receiveAtLeastView.isHidden = string == nil
            receiveAtLeastView.configureRightLabel { label in
                label.text = string
            }
        }

        private func layout() {
            stackView.spacing = 16
            stackView.addArrangedSubviews {
                fromWalletView
                UIStackView(axis: .horizontal) {
                    BEStackViewSpacing(6)
                    switchButton
                    UIView.spacer
                }
                toWalletView
                receiveAtLeastView
            }
        }

        private func bind() {

            Driver.combineLatest(
                viewModel.minimumReceiveAmountDriver,
                viewModel.destinationWalletDriver
            )
                .map { minReceiveAmount, wallet -> String? in
                    guard
                        let minReceiveAmount = minReceiveAmount,
                        let fiatPrice = wallet?.priceInCurrentFiat
                    else {
                        return nil
                    }

                    let receiveFiatPrice = (minReceiveAmount * fiatPrice).toString(maximumFractionDigits: 2)
                    let formattedReceiveFiatAmount = "(~\(Defaults.fiat.symbol)\(receiveFiatPrice))"
                    return minReceiveAmount.toString(maximumFractionDigits: 9) + " " + formattedReceiveFiatAmount
                }
                .drive { [weak self] in
                    self?.setAtLeastText(string: $0)
                }
                .disposed(by: disposeBag)
        }

        @objc
        private func switchTapped() {
            viewModel.swapSourceAndDestination()
        }
    }
}
