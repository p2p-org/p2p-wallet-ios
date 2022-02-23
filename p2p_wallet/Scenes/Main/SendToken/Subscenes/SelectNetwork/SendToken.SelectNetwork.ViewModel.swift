//
//  SendToken.SelectNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/12/2021.
//

import Foundation
import RxSwift
import RxCocoa
import FeeRelayerSwift

protocol SendTokenSelectNetworkViewModelType {
    var feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>> {get}
    var payingWalletDriver: Driver<Wallet?> {get}
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSendService() -> SendServiceType
    func getSOLAndRenBTCPrices() -> [String: Double]
    func getSelectedNetwork() -> SendToken.Network
    func getFreeTransactionFeeLimit() -> Single<FeeRelayer.Relay.FreeTransactionFeeLimit>
    func selectRecipient(_ recipient: SendToken.Recipient?)
    func selectNetwork(_ network: SendToken.Network)
    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network)
}
