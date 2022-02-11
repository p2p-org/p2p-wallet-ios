//
// Created by Giang Long Tran on 13.12.21.
//

import Foundation
import Resolver
import BEPureLayout
import UIKit

extension ReceiveToken {
    final class ViewController: BEScene {
        private var viewModel: ReceiveSceneModel
        private let isOpeningFromToken: Bool
        
        init(viewModel: ReceiveSceneModel, isOpeningFromToken: Bool) {
            self.isOpeningFromToken = isOpeningFromToken
            self.viewModel = viewModel
            super.init()

            viewModel.navigation.drive(onNext: { [weak self] in self?.navigate(to: $0) }).disposed(by: disposeBag)
        }
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                // Navbar
                if isOpeningFromToken {
                    ModalNavigationBar(
                        title: L10n.receive(viewModel.tokenWallet?.token.name ?? ""),
                        rightButtonTitle: L10n.close,
                        closeHandler: { [weak self] in
                            self?.dismiss(animated: true)
                        }
                    )
                } else {
                    NewWLNavigationBar(initialTitle: L10n.receive, separatorEnable: false)
                        .onBack { [unowned self] in self.back() }
                }
                
                BEScrollView(contentInsets: .init(x: .defaultPadding, y: .defaultPadding), spacing: 16) {
                    // Network button
                    if viewModel.shouldShowChainsSwitcher {
                        WLCard {
                            UIStackView(axis: .vertical, alignment: .fill) {
                                UIStackView(axis: .horizontal) {
                                    // Wallet Icon
                                    UIImageView(width: 44, height: 44)
                                        .with(.image, drivenBy: viewModel.tokenTypeDriver.map({ type in type.icon }), disposedBy: disposeBag)
                                    // Text
                                    UIStackView(axis: .vertical, spacing: 4, alignment: .leading) {
                                        UILabel(text: L10n.showingMyAddressFor, textSize: 13, textColor: .secondaryLabel)
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
                        .setup { [weak self] view in
                            guard let self = self else { return }

                            self.viewModel.hasHintViewOnTopDriver
                                .map { !$0 }
                                .drive(view.rx.isHidden)
                                .disposed(by: self.disposeBag)
                        }

                    ReceiveSolanaView(viewModel: viewModel.receiveSolanaViewModel)
                        .setup { view in
                            viewModel.tokenTypeDriver.map { token in token != .solana }.drive(view.rx.isHidden).disposed(by: disposeBag)
                        }
                    ReceiveBitcoinView(viewModel: viewModel.receiveBitcoinViewModel, receiveSolanaViewModel: viewModel.receiveSolanaViewModel)
                        .setup { view in
                            viewModel.tokenTypeDriver.map { token in token != .btc }.drive(view.rx.isHidden).disposed(by: disposeBag)
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
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.tabBarController?.tabBar.isHidden = false
        }
        
        override func viewWillDisappear(_ animated: Bool) { // As soon as vc disappears
            super.viewWillDisappear(true)
            self.tabBarController?.tabBar.isHidden = true
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
                    .foregroundColor: UIColor.textBlack
                ]
            )

            let highlightedRange = (attributedText.string as NSString).range(of: highlightedText, options: .caseInsensitive)
            attributedText.addAttribute(.font, value: highlightedFont, range: highlightedRange)

            qrCodeHint.attributedText = attributedText

            return qrCodeHint
        }
    }
}

extension ReceiveToken.ViewController {
    func navigate(to scene: ReceiveToken.NavigatableScene?) {
        switch scene {
        case .showInExplorer(let mintAddress):
            let url = "https://explorer.solana.com/address/\(mintAddress)"
            guard let vc = WebViewController.inReaderMode(url: url) else { return }
            present(vc, animated: true)
        case .showBTCExplorer(let address):
            let url = "https://btc.com/btc/address/\(address)"
            guard let vc = WebViewController.inReaderMode(url: url) else { return }
            present(vc, animated: true)
        case .showRenBTCReceivingStatus:
            let vm = RenBTCReceivingStatuses.ViewModel(receiveBitcoinViewModel: viewModel.receiveBitcoinViewModel)
            let vc = RenBTCReceivingStatuses.NewViewController(viewModel: vm)
            show(vc, sender: nil)
        case .share(let address, let qrCode):
            let vc = UIActivityViewController(activityItems: [qrCode, address], applicationActivities: nil)
            present(vc, animated: true)
        case .help:
            let vc = ReceiveToken.HelpViewController()
            present(vc, animated: true)
        case .networkSelection:
            let vc = ReceiveToken.NetworkSelectionScene(viewModel: viewModel)
            show(vc, sender: nil)
        case .showSupportedTokens:
            let vm = SupportedTokens.ViewModel(tokensRepository: CachedTokensRepository())
            let vc = SupportedTokens.ViewController(viewModel: vm)
            present(vc, animated: true)
        default:
            return
        }
    }
}
