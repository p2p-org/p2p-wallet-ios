//
//  TransactionDetail.FromToSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2022.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension TransactionDetail {
    final class FromToSection: UIStackView {
        private let disposeBag = DisposeBag()
        
        private let fromTitleLabel = titleLabel()
        private let fromAddressLabel = addressLabel()
        private let fromNameLabel = nameLabel()
        
        private let toTitleLabel = titleLabel()
        private let toAddressLabel = addressLabel()
        private let toNameLabel = nameLabel()
        
        init() {
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
            addArrangedSubviews {
                // Separator
                UIView.defaultSeparator()
                
                // Sender
                BEHStack(spacing: 4, alignment: .top) {
                    fromTitleLabel
                    
                    BEVStack(spacing: 8) {
                        fromAddressLabel
                        fromNameLabel
                    }
                }
                
                // Separator
                UIView.defaultSeparator()
                
                // Recipient
                BEHStack(spacing: 4, alignment: .top) {
                    toTitleLabel
                    
                    BEVStack(spacing: 8) {
                        toAddressLabel
                        toNameLabel
                    }
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func driven(with driver: Driver<SolanaSDK.ParsedTransaction?>) -> TransactionDetail.FromToSection {
            let isSwapDriver = driver.map {$0?.value is SolanaSDK.SwapTransaction}
            
            isSwapDriver
                .drive(fromNameLabel.rx.isHidden, toNameLabel.rx.isHidden)
                .disposed(by: disposeBag)
            
            isSwapDriver
                .map {$0 ? L10n.from: L10n.senderSAddress}
                .drive(fromTitleLabel.rx.text)
                .disposed(by: disposeBag)
            
            isSwapDriver
                .map {$0 ? L10n.to: L10n.recipientSAddress}
                .drive(toTitleLabel.rx.text)
                .disposed(by: disposeBag)
            
            driver
                .map {$0?.value}
                .map { transaction -> String? in
                    switch transaction {
                    case let transaction as SolanaSDK.SwapTransaction:
                        return transaction.source?.pubkey
                    case let transaction as SolanaSDK.TransferTransaction:
                        return transaction.source?.pubkey
                    default:
                        return nil
                    }
                }
                .drive(fromAddressLabel.rx.text)
                .disposed(by: disposeBag)
            
            driver
                .map {$0?.value}
                .map { transaction -> String? in
                    switch transaction {
                    case let transaction as SolanaSDK.SwapTransaction:
                        return transaction.source?.userInfo as? String
                    case let transaction as SolanaSDK.TransferTransaction:
                        return transaction.source?.userInfo as? String
                    default:
                        return nil
                    }
                }
                .drive(fromNameLabel.rx.text)
                .disposed(by: disposeBag)
            
            driver
                .map {$0?.value}
                .map { transaction -> String? in
                    switch transaction {
                    case let transaction as SolanaSDK.SwapTransaction:
                        return transaction.destination?.userInfo as? String
                    case let transaction as SolanaSDK.TransferTransaction:
                        return transaction.destination?.userInfo as? String
                    default:
                        return nil
                    }
                }
                .drive(toNameLabel.rx.text)
                .disposed(by: disposeBag)
            
            driver
                .map {$0?.value}
                .map { transaction -> String? in
                    switch transaction {
                    case let transaction as SolanaSDK.SwapTransaction:
                        return transaction.destination?.pubkey
                    case let transaction as SolanaSDK.TransferTransaction:
                        return transaction.destination?.pubkey
                    default:
                        return nil
                    }
                }
                .drive(toAddressLabel.rx.text)
                .disposed(by: disposeBag)
            
            return self
        }
    }
}

private func titleLabel() -> UILabel {
    UILabel(text: "Sender’s address", textSize: 15, textColor: .textSecondary, numberOfLines: 2)
}

private func addressLabel() -> UILabel {
    UILabel(text: "FfRBgsYFtBW7Vo5hRetqEbdxrwU8KNRn1ma6sBTBeJEr", textSize: 15, numberOfLines: 2, textAlignment: .right)
}

private func nameLabel() -> UILabel {
    UILabel(text: "name.p2p.sol", textSize: 15, textColor: .textSecondary, textAlignment: .right)
}
