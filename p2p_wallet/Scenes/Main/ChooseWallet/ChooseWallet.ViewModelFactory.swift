//
//  ChooseWallet.ViewModelFactory.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 29.12.2021.
//

import Resolver

protocol ChooseWalletViewModelFactoryType: AnyObject {
    func create(
        selectedWallet: Wallet?,
        handler: WalletDidSelectHandler,
        showOtherWallets: Bool,
        customFilter: ((Wallet) -> Bool)?
    ) -> ChooseWallet.ViewModel
}

extension ChooseWallet {
    final class ViewModelFactory: ChooseWalletViewModelFactoryType {
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var tokensRepository: TokensRepository

        func create(
            selectedWallet: Wallet?,
            handler: WalletDidSelectHandler,
            showOtherWallets: Bool,
            customFilter: ((Wallet) -> Bool)?
        ) -> ViewModel {
            .init(
                walletsRepository: walletsRepository,
                tokensRepository: tokensRepository,
                selectedWallet: selectedWallet,
                handler: handler,
                showOtherWallets: showOtherWallets
            )
        }
    }
}
