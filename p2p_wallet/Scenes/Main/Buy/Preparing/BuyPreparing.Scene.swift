//
//  Preparing.Scene.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation
import RxSwift
import RxCocoa

extension SolanaBuyToken {
    class Scene: BEScene {
        private let viewModel: SolanaBuyTokenSceneModel
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        init(viewModel: SolanaBuyTokenSceneModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
        }
        
        override func build() -> UIView {
            BEZStack {
                // Content
                BEZStackPosition(mode: .fill) {
                    content()
                }
                BEZStackPosition(mode: .pinEdges([.left, .bottom, .right], avoidKeyboard: true)) {
                    // Bottom Button
                    WLStepButton.main(text: L10n.continue)
                        .setup { view in
                            viewModel.nextStatus.map { $0.text }.drive(view.rx.text).disposed(by: disposeBag)
                            viewModel.nextStatus.map { $0.isEnable }.drive(view.rx.isEnabled).disposed(by: disposeBag)
                        }
                        .onTap { [unowned self] in self.viewModel.next() }
                        .padding(.init(all: 18))
                }
            }.onTap { [unowned self] in
                // dismiss keyboard
                view.endEditing(true)
            }
        }
        
        private func content() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                NewWLNavigationBar(initialTitle: L10n.buyOnMoonpay("Solana"))
                    .onBack { [unowned self] in self.viewModel.back() }
                
                BEScrollView(contentInsets: .init(top: 18, left: 18, bottom: 90, right: 18), spacing: 18) {
                    // Exchange
                    BEBuilder(driver: viewModel.onInputMode) { [unowned self] input in
                        switch input {
                        case .fiat:
                            return InputFiatView(viewModel: viewModel)
                        case .crypto:
                            return InputCryptoView(viewModel: viewModel)
                        }
                    }.frame(height: 148)
                        .padding(.init(all: 18))
                        .border(width: 1, color: .f2f2f7)
                        .box(cornerRadius: 12)
                        .lightShadow()
                    
                    // Description
                    UIStackView(axis: .vertical, spacing: 8, alignment: .fill) {
                        UILabel(text: "Moonpay", weight: .bold)
                        UIView.defaultSeparator()
                        
                        descriptionRow(label: "SOL Price", initial: "$ 0.0", viewModel.exchangeRateStringDriver)
                        descriptionRow(label: L10n.processingFee, initial: "$ 0.00", viewModel.feeAmount.map { "$ \($0)" })
                        descriptionRow(label: L10n.networkFee, initial: "$ 0.00", viewModel.networkFee.map { "$ \($0)" })
                        descriptionRow(label: L10n.total, initial: "$ 0.00", viewModel.total.map { "$ \($0)" })
                    }.padding(.init(all: 18))
                }
            }
        }
        
        private func descriptionRow(label: String, initial: String, _ trailingDriver: Driver<String>? = nil) -> UIView {
            UIStackView(axis: .horizontal, alignment: .fill) {
                UILabel(text: label, textColor: .secondaryLabel)
                UIView.spacer
                UILabel(text: initial).setup { view in
                    trailingDriver?.drive(view.rx.text).disposed(by: disposeBag)
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

extension SolanaBuyTokenSceneModel {
    fileprivate var onInputMode: Driver<InputMode> {
        inputDriver
            .map { input in
                if input.currency is Buy.CryptoCurrency {
                    return .crypto
                } else {
                    return .fiat
                }
            }
            .distinctUntilChanged { $0 }
    }
    
    fileprivate var exchangeRateStringDriver: Driver<String> {
        exchangeRateDriver
            .map { rate in
                if rate != nil {
                    return "$ \(rate!.amount.toString())"
                } else {
                    return ""
                }
            }
    }
    
    fileprivate var feeAmount: Driver<Double> {
        outputDriver.map { $0.processingFee }
    }
    
    fileprivate var networkFee: Driver<Double> {
        outputDriver.map { $0.networkFee }
    }
    
    fileprivate var total: Driver<Double> {
        outputDriver.map { $0.total }
    }
    
    fileprivate var nextStatus: Driver<NextStatus> {
        Driver
            .combineLatest(inputDriver, minUSDAmount, minSOLAmount)
            .map { (input, minUSD, minSol) in
                if minUSD == 0 || minSol == 0 {
                    return NextStatus.init(text: L10n.loading, isEnable: false)
                }
                
                if input.currency is Buy.FiatCurrency {
                    if input.amount < minUSD {
                        return NextStatus.init(text: L10n.minimumPurchaseOfRequired("$\(minUSD)"), isEnable: false)
                    }
                    return NextStatus.init(text: L10n.continue, isEnable: true)
                } else {
                    if input.amount < minSol {
                        return NextStatus.init(text: L10n.minimumPurchaseOfRequired("\(minSol) SOL"), isEnable: false)
                    }
                    return NextStatus.init(text: L10n.continue, isEnable: true)
                }
            }
    }
    
}
