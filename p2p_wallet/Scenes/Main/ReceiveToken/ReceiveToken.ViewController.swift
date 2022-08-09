//
// Created by Giang Long Tran on 13.12.21.
//

import BEPureLayout
import Foundation
import Resolver
import UIKit

extension ReceiveToken {
    final class ViewController: BaseViewController {
        private var viewModel: ReceiveSceneModel
        private let isOpeningFromToken: Bool

        init(viewModel: ReceiveSceneModel, isOpeningFromToken: Bool) {
            self.isOpeningFromToken = isOpeningFromToken
            self.viewModel = viewModel
            super.init()

            viewModel.navigation.drive(onNext: { [weak self] in self?.navigate(to: $0) }).disposed(by: disposeBag)

            if isOpeningFromToken {
                navigationItem.title = "\(L10n.receive) \(viewModel.tokenWallet?.token.name ?? "")"
                let closeButton = UIBarButtonItem(
                    title: L10n.close,
                    style: .plain,
                    target: self,
                    action: #selector(goBack)
                )
                navigationItem.rightBarButtonItem = closeButton
            } else {
                navigationItem.title = L10n.receive
            }
            hidesBottomBarWhenPushed = true
        }

        @objc func goBack() {
            dismiss(animated: true)
        }

        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                BEScrollView(contentInsets: .init(x: .defaultPadding, y: .defaultPadding), spacing: 16) {
                    // Network button
                    if viewModel.shouldShowChainsSwitcher {
                        WLCard {
                            UIStackView(axis: .vertical, alignment: .fill) {
                                UIStackView(axis: .horizontal) {
                                    // Wallet Icon
                                    UIImageView(width: 44, height: 44)
                                        .setup { imageView in
                                            viewModel.tokenTypeDriver.map { type in type.icon }
                                                .drive(imageView.rx.image)
                                                .disposed(by: disposeBag)
                                        }
                                    // Text
                                    UIStackView(axis: .vertical, spacing: 4, alignment: .leading) {
                                        UILabel(
                                            text: L10n.showingMyAddressFor,
                                            textSize: 13,
                                            textColor: .secondaryLabel
                                        )
                                        UILabel(text: L10n.network("Solana"), textSize: 17, weight: .semibold)
                                            .setup { view in
                                                viewModel.tokenTypeDriver
                                                    .map { L10n.network($0.localizedName).onlyUppercaseFirst() }
                                                    .drive(view.rx.text)
                                                    .disposed(by: disposeBag)
                                            }
                                    }.padding(.init(x: 12, y: 0))
                                    // Next icon
                                    UIView.defaultNextArrow()
                                }
                                .padding(.init(x: 15, y: 15))
                                .onTap { [unowned self] in
                                    self.viewModel.showSelectionNetwork()
                                }
                                UIStackView(axis: .vertical, alignment: .fill) {
                                    UIView(height: 1, backgroundColor: .f2f2f7)
                                    UIButton(
                                        height: 50,
                                        label: L10n.whatTokensCanIReceive,
                                        labelFont: .systemFont(ofSize: 15, weight: .medium),
                                        textColor: .h5887ff
                                    ).onTap { [weak self] in
                                        self?.navigate(to: .showSupportedTokens)
                                    }
                                }
                                .setup { [weak viewModel] view in
                                    viewModel?.tokenListAvailabilityDriver
                                        .map { !$0 }
                                        .drive(view.rx.isHidden)
                                        .disposed(by: disposeBag)
                                }
                            }
                        }
                    }
                    // Children
                    UIView.greyBannerView {
                        createQRHint()
                    }
                    .setup { view in
                        viewModel.hasHintViewOnTopDriver
                            .map { !$0 }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                    ReceiveSolanaView(viewModel: viewModel.receiveSolanaViewModel)
                        .setup { view in
                            viewModel.tokenTypeDriver.map { token in token != .solana }.drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                        }
                    ReceiveBitcoinView(
                        viewModel: viewModel.receiveBitcoinViewModel
                    )
                        .setup { view in
                            viewModel.tokenTypeDriver.map { token in token != .btc }.drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                        }

                    UIStackView(axis: .vertical, spacing: 16, alignment: .fill) {
                        ShowHideButton(
                            closedText: L10n.showDirectAndMintAddresses,
                            openedText: L10n.hideDirectAndMintAddresses
                        )
                            .setup { view in
                                viewModel.addressesInfoIsOpenedDriver
                                    .drive(view.rx.isOpened)
                                    .disposed(by: disposeBag)
                                view.rx.tap
                                    .bind(to: viewModel.showHideAddressesInfoButtonTapSubject)
                                    .disposed(by: disposeBag)
                            }
                        TokenAddressesView(viewModel: viewModel)
                            .setup { view in
                                viewModel.addressesInfoIsOpenedDriver
                                    .drive { [weak view] isOpened in
                                        UIView.animate(withDuration: 0.3) {
                                            view?.isHidden = !isOpened
                                        }
                                    }
                                    .disposed(by: disposeBag)
                            }
                            .padding(.init(only: .top, inset: 18))
                    }
                    .setup { view in
                        viewModel.hasAddressesInfoDriver
                            .map { !$0 }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }
                }
            }
        }

        private func createQRHint() -> UILabel {
            let symbol = viewModel.tokenWallet?.token.symbol ?? ""
            let qrCodeHint = UILabel(numberOfLines: 0)
            let highlightedText = L10n.receive(symbol)
            let fullText = L10n.youCanReceiveByProvidingThisAddressQRCodeOrUsername(symbol)

            let normalFont = UIFont.systemFont(ofSize: 15, weight: .regular)
            let highlightedFont = UIFont.systemFont(ofSize: 15, weight: .bold)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.17
            paragraphStyle.alignment = .center

            let attributedText = NSMutableAttributedString(
                string: fullText,
                attributes: [
                    .font: normalFont,
                    .kern: -0.24,
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: UIColor.textBlack,
                ]
            )

            let highlightedRange = (attributedText.string as NSString)
                .range(of: highlightedText, options: .caseInsensitive)
            attributedText.addAttribute(.font, value: highlightedFont, range: highlightedRange)

            qrCodeHint.attributedText = attributedText

            return qrCodeHint
        }
    }
}

extension ReceiveToken.ViewController {
    func navigate(to scene: ReceiveToken.NavigatableScene?) {
        switch scene {
        case let .showInExplorer(mintAddress):
            let url = "https://explorer.solana.com/address/\(mintAddress)"
            guard let vc = WebViewController.inReaderMode(url: url) else { return }
            present(vc, animated: true)
        case let .showBTCExplorer(address):
            let url = "https://btc.com/btc/address/\(address)"
            guard let vc = WebViewController.inReaderMode(url: url) else { return }
            present(vc, animated: true)
        case .showRenBTCReceivingStatus:
            let vm = RenBTCReceivingStatuses.ViewModel(receiveBitcoinViewModel: viewModel.receiveBitcoinViewModel)
            let vc = RenBTCReceivingStatuses.ViewController(viewModel: vm)
            show(vc, sender: nil)
        case let .share(address, qrCode):
            guard let qrCode = qrCode, let address = address else {
                return
            }

            let vc = UIActivityViewController(activityItems: [qrCode, address], applicationActivities: nil)
            present(vc, animated: true)
        case .help:
            let vc = ReceiveToken.HelpViewController()
            present(vc, animated: true)
        case .networkSelection:
            let vc = ReceiveToken.NetworkSelectionScene(viewModel: viewModel)
            show(vc, sender: nil)
        case .showSupportedTokens:
            let vm = SupportedTokens.ViewModel()
            let vc = SupportedTokens.ViewController(viewModel: vm)
            present(vc, animated: true)
        case .showPhotoLibraryUnavailable:
            PhotoLibraryAlertPresenter().present(on: self)
        case .buy:
            present(
                BuyTokenSelection.Scene(onTap: { [unowned self] crypto in
                    let vm = BuyRoot.ViewModel()
                    let vc = BuyRoot.ViewController(crypto: crypto, viewModel: vm)
                    show(vc, sender: nil)
                }),
                animated: true
            )
        case .none:
            return
        }
    }
}
