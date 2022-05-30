//
//  SendToken.SelectNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/12/2021.
//

import FeeRelayerSwift
import Foundation
import RxCocoa
import RxSwift

protocol SendTokenSelectNetworkViewModelType {
    var feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>> { get }
    var payingWalletDriver: Driver<Wallet?> { get }
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSendService() -> SendServiceType
    func getPrices(for symbols: [String]) -> [String: Double]
    func getSelectedNetwork() -> SendToken.Network
    func getFreeTransactionFeeLimit() -> Single<UsageStatus>
    func selectRecipient(_ recipient: SendToken.Recipient?)
    func selectNetwork(_ network: SendToken.Network)
    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network)
}
