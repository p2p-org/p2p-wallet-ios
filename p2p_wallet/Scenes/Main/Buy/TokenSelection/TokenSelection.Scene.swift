//
// Created by Giang Long Tran on 04.03.2022.
//

import BEPureLayout
import UIKit

extension BuyTokenSelection {
    class Scene: WLBottomSheet {
        @Injected var walletRepository: WalletsRepository
        @Injected var tokenRepository: TokensRepository

        private var onTap: BECallback<Buy.CryptoCurrency>?
        override var padding: UIEdgeInsets { .zero }

        init(onTap: BECallback<Buy.CryptoCurrency>?) {
            self.onTap = onTap
            super.init()
        }

        override func build() -> UIView {
            BEVStack {
                UILabel(text: L10n.chooseATokenForBuying, textSize: 20, weight: .semibold, textAlignment: .center)
                    .padding(.init(x: 0, y: 18))

                UIView.separator(height: 1, color: .separator)
                UIView(height: 14)

                cell(cryptoCurrency: .sol)
                    .onTap { [unowned self] in self.onTap(crypto: .sol) }
                cell(cryptoCurrency: .usdc)
                    .onTap { [unowned self] in self.onTap(crypto: .usdc) }
            }
        }

        private func onTap(crypto: Buy.CryptoCurrency) {
            dismiss(animated: true) { [unowned self] in onTap?(crypto) }
        }

        private func cell(cryptoCurrency: Buy.CryptoCurrency) -> UIView {
            Cell()
                .setupWithType(Cell.self) { cell in
                    if let wallet = walletRepository.getWallets().first(where: {
                        $0.token.symbol == cryptoCurrency.tokenName
                    }) {
                        cell.setup(wallet: wallet)
                    } else {
                        tokenRepository
                            .getTokensList()
                            .asDriver(onErrorJustReturn: [])
                            .drive(onNext: { [weak cell] tokens in
                                guard let token = tokens.first(where: { $0.symbol == cryptoCurrency.tokenName }) else {
                                    cell?.isHidden = true
                                    return
                                }
                                cell?.setUp(token: token, amount: 0, amountInFiat: 0)
                            })
                            .disposed(by: disposeBag)
                    }
                }
        }

        class Cell: BECompositionView {
            private var iconRef = BERef<CoinLogoImageView>()
            private var coinNameRef = BERef<UILabel>()
            private var amountRef = BERef<UILabel>()
            private var amountInFiatRef = BERef<UILabel>()

            override func build() -> UIView {
                BEHStack {
                    // Icon
                    CoinLogoImageView(size: 44, cornerRadius: 12)
                        .bind(iconRef)
                        .centered(.vertical)

                    UIView(width: 12)

                    // Title
                    BEVStack {
                        UILabel(text: "<Coin name>", textSize: 17, weight: .medium)
                            .bind(coinNameRef)
                        UILabel(text: "<Amount>", textSize: 13, textColor: .secondaryLabel)
                            .bind(amountRef)
                    }
                    UIView.spacer

                    // Trailing
                    BEVStack(alignment: .trailing) {
                        UILabel(text: "<Amount in fiat>", textSize: 17, weight: .medium)
                            .bind(amountInFiatRef)
                    }
                }.padding(.init(x: 18, y: 12))
            }

            @discardableResult
            func setup(wallet: Wallet) -> Self {
                iconRef.view?.setUp(wallet: wallet)
                if wallet.name.isEmpty {
                    coinNameRef.view?.text = wallet.mintAddress.prefix(4) + "..." + wallet.mintAddress.suffix(4)
                } else {
                    coinNameRef.view?.text = wallet.token.name.uppercaseFirst
                }
                amountRef.view?.text = "\(wallet.amount.toString(maximumFractionDigits: 9)) \(wallet.token.symbol)"
                amountInFiatRef.view?
                    .text = "\(Defaults.fiat.symbol) \(wallet.amountInCurrentFiat.toString(maximumFractionDigits: 2))"
                return self
            }

            @discardableResult
            func setUp(token: SolanaSDK.Token, amount: Double?, amountInFiat: Double?) -> Self {
                print(token)
                iconRef.view?.setUp(token: token)
                coinNameRef.view?.text = token.name
                amountRef.view?.text = "\(amount.toString(maximumFractionDigits: 9)) \(token.symbol)"
                amountInFiatRef.view?
                    .text = "\(Defaults.fiat.symbol) \(amountInFiat.toString(maximumFractionDigits: 2))"
                return self
            }
        }
    }
}
