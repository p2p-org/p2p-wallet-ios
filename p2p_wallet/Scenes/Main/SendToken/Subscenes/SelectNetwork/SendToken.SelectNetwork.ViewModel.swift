//
//  SendToken.SelectNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/12/2021.
//

import Combine
import FeeRelayerSwift
import Foundation
import SolanaSwift

protocol SendTokenSelectNetworkViewModelType {
    var feeInfoPublisher: AnyPublisher<Loadable<SendToken.FeeInfo>, Never> { get }
    var payingWalletPublisher: AnyPublisher<Wallet?, Never> { get }
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSendService() -> SendServiceType
    func getPrices(for symbols: [String]) -> [String: Double]
    func getSelectedNetwork() -> SendToken.Network
    func getFreeTransactionFeeLimit() async throws -> UsageStatus
    func selectRecipient(_ recipient: SendToken.Recipient?)
    func selectNetwork(_ network: SendToken.Network)
    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network)
}
