//
//  Preparing.Scene.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import BEPureLayout
import Combine
import Foundation
import Resolver
import SafariServices
import WebKit

extension BuyPreparing {
    final class Scene: BaseViewController {
        private let viewModel: BuyPreparingSceneModel
        private let infoToggle = CurrentValueSubject<Bool, Never>(false)
        private var subscriptions = [AnyCancellable]()

        init(viewModel: BuyPreparingSceneModel) {
            self.viewModel = viewModel
            super.init()
            navigationItem.title = L10n.buying(viewModel.crypto.fullname)
            hidesBottomBarWhenPushed = true
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            view.endEditing(true)
        }

        // MARK: - Navigation

        private func navigateToWeb() {
            do {
                let factory: BuyProcessingFactory = Resolver.resolve()
                let provider = try factory.create(
                    walletRepository: viewModel.walletsRepository,
                    crypto: viewModel.crypto,
                    initialAmount: viewModel.amount,
                    currency: .usd
                )
                let dataTypes = Set([WKWebsiteDataTypeCookies,
                                     WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage,
                                     WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
                WKWebsiteDataStore.default()
                    .removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) { [weak self] in
                        let vc = SFSafariViewController(url: URL(string: provider.getUrl())!)
                        vc.modalPresentationStyle = .automatic
                        self?.present(vc, animated: true)
                    }
            } catch let e {
                print(e)
            }
        }

        override func build() -> UIView {
            BEZStack {
                // Content
                BEZStackPosition(mode: .fill) {
                    content()
                }
                BEZStackPosition(mode: .pinEdges([.left, .bottom, .right], avoidKeyboard: true)) {
                    // Bottom Button
                    BESafeArea {
                        WLStepButton.main(text: L10n.continue)
                            .setup { view in
                                viewModel.nextStatus.map(\.text)
                                    .receive(on: RunLoop.main)
                                    .sink { [weak view] in view?.text = $0 }
                                    .store(in: &subscriptions)
                                viewModel.nextStatus.map(\.isEnable)
                                    .receive(on: RunLoop.main)
                                    .assign(to: \.isEnabled, on: view)
                                    .store(in: &subscriptions)
                            }
                            .onTap { [unowned self] in navigateToWeb() }
                            .padding(.init(all: 18))
                    }
                }
            }.onTap { [unowned self] in
                // dismiss keyboard
                view.endEditing(true)
            }
        }

        private func content() -> UIView {
            BEScrollView(contentInsets: .init(top: 18, left: 18, bottom: 90, right: 18), spacing: 18) {
                // Exchange
                WLCard {
                    BEVStack {
                        BEBuilder(publisher: viewModel.onInputMode) { [unowned self] input in
                            switch input {
                            case .fiat:
                                return InputFiatView(viewModel: viewModel)
                            case .crypto:
                                return InputCryptoView(viewModel: viewModel)
                            }
                        }.padding(.init(x: 18, y: 18))

                        UIView.defaultSeparator()

                        BEVStack {
                            descriptionRow(
                                label: "\(viewModel.crypto.name) \(L10n.price)",
                                initial: "$ 0.0",
                                viewModel.exchangeRateStringAnyPublisher
                            )

                            BEHStack(alignment: .center) {
                                UILabel(text: L10n.hideFees)
                                    .setup { view in
                                        self.infoToggle
                                            .sink { [weak view] value in
                                                view?.text = value ? L10n.hideFees : L10n.showFees
                                            }
                                            .store(in: &subscriptions)
                                    }
                                UIImageView(image: .chevronDown, tintColor: .black)
                                    .setup { view in
                                        self.infoToggle
                                            .sink { [weak view] value in
                                                view?.image = value ? .chevronUp : .chevronDown
                                            }
                                            .store(in: &subscriptions)
                                    }
                            }
                            .centered(.horizontal)
                            .padding(.init(only: .top, inset: 18))
                            .onTap { [unowned self] in infoToggle.send(!infoToggle.value) }

                            BEBuilder(publisher: infoToggle.eraseToAnyPublisher()) { [weak self] value in
                                guard let self = self else { return UIView() }
                                return value ? self.feeInfo() : UIView()
                            }

                        }.padding(.init(x: 18, y: 18))
                    }
                }
            }
        }

        private func feeInfo() -> UIView {
            BEVStack {
                UIView(height: 18)
                descriptionRow(
                    label: L10n.purchaseCost("\(viewModel.crypto.name)"),
                    initial: "$ 0.00",
                    viewModel.purchaseCost
                )
                UIView(height: 8)
                descriptionRow(
                    label: L10n.processingFee,
                    initial: "$ 0.00",
                    viewModel.feeAmount
                )
                UIView(height: 8)
                descriptionRow(
                    label: L10n.networkFee,
                    initial: "$ 0.00",
                    viewModel.networkFee
                )
                UIView(height: 8)

                UIView.defaultSeparator()
                UIView(height: 8)
                totalRow(label: L10n.total, initial: "$ 0.00", viewModel.total)
            }
        }

        private func descriptionRow(label: String, initial: String,
                                    _ trailingAnyPublisher: AnyPublisher<String, Never>? = nil) -> UIView
        {
            UIStackView(axis: .horizontal, alignment: .fill) {
                UILabel(text: label, textColor: .secondaryLabel)
                UIView.spacer
                UILabel(text: initial).setup { view in
                    trailingAnyPublisher?.map { Optional($0) }.assign(to: \.text, on: view).store(in: &subscriptions)
                }
            }
        }

        private func totalRow(label: String, initial: String,
                              _ trailingAnyPublisher: AnyPublisher<String, Never>? = nil) -> UIView
        {
            UIStackView(axis: .horizontal, alignment: .fill) {
                UILabel(text: label)
                UIView.spacer
                UILabel(text: initial, weight: .bold).setup { view in
                    trailingAnyPublisher?.map { Optional($0) }.assign(to: \.text, on: view).store(in: &subscriptions)
                }
            }
        }
    }
}

private struct NextStatus {
    let text: String
    let isEnable: Bool
}

private enum InputMode {
    case fiat
    case crypto
}

private extension BuyPreparingSceneModel {
    var onInputMode: AnyPublisher<InputMode, Never> {
        inputAnyPublisher
            .map { input in
                if input.currency is Buy.CryptoCurrency {
                    return .crypto
                } else {
                    return .fiat
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var exchangeRateStringAnyPublisher: AnyPublisher<String, Never> {
        exchangeRateAnyPublisher
            .map { rate -> String in
                if let rate = rate {
                    return "$ \(rate.amount)"
                } else {
                    return ""
                }
            }
            .map { "$ \($0.fiatFormat)" }
            .eraseToAnyPublisher()
    }

    var feeAmount: AnyPublisher<String, Never> {
        outputAnyPublisher.map(\.processingFee.convertedFiat).eraseToAnyPublisher()
    }

    var networkFee: AnyPublisher<String, Never> {
        outputAnyPublisher.map(\.networkFee.convertedFiat).eraseToAnyPublisher()
    }

    var total: AnyPublisher<String, Never> {
        outputAnyPublisher.map(\.total.convertedFiat).eraseToAnyPublisher()
    }

    var purchaseCost: AnyPublisher<String, Never> {
        outputAnyPublisher.map(\.purchaseCost.convertedFiat).eraseToAnyPublisher()
    }

    var nextStatus: AnyPublisher<NextStatus, Never> {
        Publishers
            .CombineLatest3(inputAnyPublisher, minFiatAmount, minCryptoAmount)
            .map { [weak self] input, minUSD, minSol in
                if minUSD == 0 || minSol == 0 {
                    return NextStatus(text: L10n.loading, isEnable: false)
                }

                if input.currency is Buy.FiatCurrency {
                    if input.amount < minUSD {
                        return NextStatus(
                            text: L10n.minimumPurchaseOfRequired("$\(minUSD.fixedDecimal(2))"),
                            isEnable: false
                        )
                    }
                    return NextStatus(text: L10n.continue, isEnable: true)
                } else {
                    if input.amount < minSol {
                        return NextStatus(
                            text: L10n
                                .minimumPurchaseOfRequired("\(minSol) \(self?.crypto.name ?? "?")"),
                            isEnable: false
                        )
                    }
                    return NextStatus(text: L10n.continue, isEnable: true)
                }
            }
            .eraseToAnyPublisher()
    }
}

private extension Double {
    var convertedFiat: String {
        "$ \(toString(maximumFractionDigits: 2, groupingSeparator: " "))"
    }
}
