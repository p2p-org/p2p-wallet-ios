//
//  HomeVersion2ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 23/06/2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver

class HomeVersion2ViewModel: BaseViewModel, ObservableObject {
    @Published var totalAmountInFiat: String = ""
    @Published var iconsURL: [URL] = []

    init(totalAmountInFiat: String, iconsURL: [URL]) {
        super.init()
        self.iconsURL = iconsURL
        self.totalAmountInFiat = totalAmountInFiat
    }

    init(solanaAccountService: SolanaAccountsService = Resolver.resolve()) {
        super.init()

        solanaAccountService
            .statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in

                var sum: CurrencyAmount = .zero
                let currencyFormatter: CurrencyFormatter = .init()
                var icons: [URL] = []
                let primaryTokenList: [SolanaToken] = [SolanaToken.usdc, SolanaToken.usdt]
                
                for account in state.value {
                    if !primaryTokenList.map(\.address).contains(account.data.token.address) {
                        
                        continue
                    }
                    if let amountInfiat = account.amountInFiat {
                        
                        sum = sum + amountInfiat
                    }
                    if let iconUrl: String = account.data.token.logoURI {
                        
                        if let url = URL(string: iconUrl) {
                            
                            icons.append(url)
                        }
                    }
                }
                self?.totalAmountInFiat = currencyFormatter.string(amount: sum)
                self?.iconsURL = icons
            }
            .store(in: &subscriptions)
    }
}
