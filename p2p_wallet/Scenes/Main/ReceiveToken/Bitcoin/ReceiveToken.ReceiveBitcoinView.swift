//
//  ReceiveToken.ReceiveBitcoinView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

extension ReceiveToken {
    class ReceiveBitcoinView: BECompositionView {
        private let disposeBag = DisposeBag()
        private let viewModel: ReceiveTokenBitcoinViewModelType
        private let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        
        // MARK: - Initializers
        init(
            viewModel: ReceiveTokenBitcoinViewModelType,
            receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        ) {
            self.viewModel = viewModel
            self.receiveSolanaViewModel = receiveSolanaViewModel
            super.init(frame: .zero)
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, spacing: 18, alignment: .fill) {
                
                // Qr code
                QrCodeCard(token: .renBTC)
                    .onCopy { [unowned self] _ in
                        self.viewModel.copyToClipboard()
                    }.onShare { [unowned self] _ in
                        self.viewModel.share()
                    }.onSave { image in
                        self.viewModel.saveAction(image: image)
                    }.setupWithType(QrCodeCard.self) { card in
                        viewModel.addressDriver.drive(card.rx.pubKey).disposed(by: disposeBag)
                    }
                
                // Status
                WLCard {
                    UIStackView(axis: .horizontal) {
                        UIImageView(image: .receiveSquircle)
                            .frame(width: 44, height: 44)
                        UIStackView(axis: .vertical, alignment: .fill) {
                            UILabel(text: L10n.statusesReceived, textSize: 17)
                            UILabel(text: "\(L10n.theLastOne) 0m ago", textSize: 13, textColor: .secondaryLabel)
                                .setupWithType(UILabel.self) { view in
                                    viewModel.processingTxsDriver
                                        .map { $0.count == 0 }
                                        .drive(view.rx.isHidden)
                                        .disposed(by: disposeBag)
                                    viewModel.processingTxsDriver
                                        .map { trx in
                                            guard let lastTrx = trx.first,
                                                  let receiveAt = lastTrx.receivedAt else { return "" }
                                            
                                            // Time formatter
                                            let formatter = RelativeDateTimeFormatter()
                                            formatter.unitsStyle = .short
                                            let time = formatter.localizedString(for: Date(), relativeTo: receiveAt)
                                            
                                            return "\(L10n.theLastOne) \(time)"
                                        }
                                        .drive(view.rx.text)
                                        .disposed(by: disposeBag)
                                }
                        }
                        UIView.spacer
                        UILabel(text: "0")
                            .setupWithType(UILabel.self) { view in
                                viewModel.processingTxsDriver
                                    .map { trx in "\(trx.count)" }
                                    .drive(view.rx.text)
                                    .disposed(by: disposeBag)
                            }
                            .padding(.init(only: .right, inset: 8))
                        UIView.defaultNextArrow()
                    }.padding(.init(x: 18, y: 14))
                }.onTap { [unowned self] in
                    self.viewModel.showReceivingStatuses()
                }
                
                // Description
                UIView.greyBannerView(spacing: 12) {
                    ReceiveToken.textBuilder(text: L10n.ThisAddressAcceptsOnly.youMayLoseAssetsBySendingAnotherCoin(L10n.onlyBitcoin).asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())
                        .setup { view in
                            guard let textLabel = view.viewWithTag(1) as? UILabel else { return }
                            viewModel.timerSignal.map { [weak self] in
                                guard let self = self else { return L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown() }
                                guard let endAt = self.viewModel.getSessionEndDate()
                                    else { return L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown() }
                                let currentDate = Date()
                                let calendar = Calendar.current
                                
                                let d = calendar.dateComponents([.hour, .minute, .second], from: currentDate, to: endAt)
                                let countdown = String(format: "%02d:%02d:%02d", d.hour ?? 0, d.minute ?? 0, d.second ?? 0)
                                
                                return L10n.isTheRemainingTimeToSafelySendTheAssets(countdown).asMarkdown()
                            }.emit(to: textLabel.rx.attributedText).disposed(by: disposeBag)
                        }
                }
                
                WLStepButton.main(image: .external, imageSize: .init(width: 14, height: 14), text: L10n.viewInExplorer("Solana"))
                    .padding(.init(only: .top, inset: 18))
                    .onTap { [unowned self] in self.viewModel.showBTCAddressInExplorer() }
            }
        }
    }
}
