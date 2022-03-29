//
//  TransactionDetail.NavigationBar.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2022.
//

import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

extension TransactionDetail {
    final class NavigationBar: NewWLNavigationBar {
        private let disposeBag = DisposeBag()

        func driven(with driver: Driver<SolanaSDK.ParsedTransaction?>) -> TransactionDetail.NavigationBar {
            driver
                .map { parsedTransaction -> String in
                    var text = L10n.transaction

                    switch parsedTransaction?.value {
                    case let createAccountTransaction as SolanaSDK.CreateAccountTransaction:
                        if let createdToken = createAccountTransaction.newWallet?.token.symbol {
                            text = L10n.created(createdToken)
                        }
                    case let closedAccountTransaction as SolanaSDK.CloseAccountTransaction:
                        if let closedToken = closedAccountTransaction.closedWallet?.token.symbol {
                            text = L10n.closed(closedToken)
                        }

                    case let transferTransaction as SolanaSDK.TransferTransaction:
                        if let symbol = transferTransaction.source?.token.symbol,
                           let receiverPubkey = transferTransaction.destination?.pubkey
                        {
                            text = symbol + " → " + receiverPubkey
                                .truncatingMiddle(numOfSymbolsRevealed: 4, numOfSymbolsRevealedInSuffix: 4)
                        }

                    case let swapTransaction as SolanaSDK.SwapTransaction:
                        if let sourceSymbol = swapTransaction.source?.token.symbol ?? swapTransaction.source?
                            .mintAddress.truncatingMiddle(
                                numOfSymbolsRevealed: 4,
                                numOfSymbolsRevealedInSuffix: 4
                            ),
                            let destinationSymbol = swapTransaction.destination?.token.symbol ?? swapTransaction
                                .destination?.mintAddress.truncatingMiddle(
                                    numOfSymbolsRevealed: 4,
                                    numOfSymbolsRevealedInSuffix: 4
                                )
                        {
                            text = sourceSymbol + " → " + destinationSymbol
                        }
                    default:
                        break
                    }

                    return text
                }
                .drive(titleLabel.rx.text)
                .disposed(by: disposeBag)
            return self
        }
    }
}
