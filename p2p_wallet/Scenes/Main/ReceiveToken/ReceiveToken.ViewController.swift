//
// Created by Giang Long Tran on 13.12.21.
//

import AnalyticsManager
import BEPureLayout
import Combine
import KeyAppUI
import Resolver
import UIKit
import CombineCocoa

extension ReceiveToken {
    final class ViewController: BaseViewController {
        private var viewModel: ReceiveSceneModel
        private let isOpeningFromToken: Bool
        private var subscriptions = Set<AnyCancellable>()
        private var buyCoordinator: BuyCoordinator?

        @Injected private var analyticsManager: AnalyticsManager

        init(viewModel: ReceiveSceneModel, isOpeningFromToken: Bool) {
            self.isOpeningFromToken = isOpeningFromToken
            self.viewModel = viewModel
            super.init()

            viewModel.navigationPublisher.sink(receiveValue: { [weak self] in self?.navigate(to: $0) }).store(in: &subscriptions)

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

            analyticsManager.log(event: .receiveStartScreen)
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
                                        .setup { view in
                                            viewModel.tokenTypePublisher.map { type in type.icon }
                                                .assign(to: \.image, on: view)
                                                .store(in: &subscriptions)
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
                                                viewModel.tokenTypePublisher
                                                    .map { L10n.network($0.localizedName).onlyUppercaseFirst() }
                                                    .assign(to: \.text, on: view)
                                                    .store(in: &subscriptions)
                                            }
                                    }.padding(.init(x: 12, y: 0))
                                    if !viewModel.isDisabledRenBtc {
                                        UIView.defaultNextArrow()
                                    }
                                }
                                .padding(.init(x: 15, y: 15))
                                .onTap { [unowned self] in
                                    viewModel.showSelectionNetwork()
                                }
                                UIStackView(axis: .vertical, alignment: .fill) {
                                    UIView(height: 1, backgroundColor: .f2f2f7)
                                    UIButton(
                                        height: 50,
                                        label: L10n.whatTokensCanIReceive,
                                        labelFont: .systemFont(ofSize: 15, weight: .medium),
                                        textColor: Asset.Colors.night.color
                                    ).onTap { [weak self] in
                                        self?.navigate(to: .showSupportedTokens)
                                    }
                                }
                                .setup { [weak viewModel] view in
                                    viewModel?.tokenListAvailabilityPublisher
                                        .map { !$0 }
                                        .assign(to: \.isHidden, on: view)
                                        .store(in: &subscriptions)
                                }
                            }
                        }
                    }
                    // Children
                    UIView.greyBannerView {
                        createQRHint()
                    }
                    .setup { view in
                        viewModel.hasHintViewOnTopPublisher
                            .map { !$0 }
                            .assign(to: \.isHidden, on: view)
                            .store(in: &subscriptions)
                    }

                    ReceiveSolanaView(viewModel: viewModel.receiveSolanaViewModel)
                        .setup { view in
                            viewModel.tokenTypePublisher.map { token in token != .solana }.assign(to: \.isHidden, on: view).store(in: &subscriptions)
                        }
                    ReceiveBitcoinView(viewModel: viewModel.receiveBitcoinViewModel).setup { view in
                        viewModel.tokenTypePublisher
                            .map { token in token != .btc }
                            .assign(to: \.isHidden, on: view)
                            .store(in: &subscriptions)
                    }

                    UIStackView(axis: .vertical, spacing: 16, alignment: .fill) {
                        ShowHideButton(
                            closedText: L10n.showDirectAndMintAddresses,
                            openedText: L10n.hideDirectAndMintAddresses
                        )
                            .setup { view in
                                viewModel.addressesInfoIsOpenedPublisher
                                    .assign(to: \.isOpened, on: view)
                                    .store(in: &subscriptions)
                                view.tapPublisher
                                    .sink { [weak viewModel] _ in
                                        viewModel?.showHideAddressesInfoButtonTapSubject.send()
                                    }
                                    .store(in: &subscriptions)
                            }
                        TokenAddressesView(viewModel: viewModel)
                            .setup { view in
                                viewModel.addressesInfoIsOpenedPublisher
                                    .sink { [weak view] isOpened in
                                        UIView.animate(withDuration: 0.3) {
                                            view?.isHidden = !isOpened
                                        }
                                    }
                                    .store(in: &subscriptions)
                            }
                            .padding(.init(only: .top, inset: 18))
                    }
                    .setup { view in
                        viewModel.hasAddressesInfoPublisher
                            .map { !$0 }
                            .assign(to: \.isHidden, on: view)
                            .store(in: &subscriptions)
                    }
                }
            }
        }

        private func createQRHint() -> UILabel {
            let qrCodeHint = UILabel(numberOfLines: 0)
            qrCodeHint.attributedText = viewModel.qrHint
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
            show(UINavigationController(rootViewController: vc), sender: nil)
        case let .share(address, qrCode):
            analyticsManager.log(event: .QR_Share)
            guard let qrCode = qrCode, let address = address else { return }

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
            buyCoordinator = BuyCoordinator(
                context: .fromRenBTC,
                presentingViewController: self,
                shouldPush: false
            )
            buyCoordinator?.start()
                .sink { _ in }
                .store(in: &subscriptions)
        case .none:
            return
        }
    }
}
