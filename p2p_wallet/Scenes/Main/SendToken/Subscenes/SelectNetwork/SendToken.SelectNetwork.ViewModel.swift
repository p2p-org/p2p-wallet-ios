//
//  SendToken.SelectNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/12/2021.
//

import Foundation

protocol SendTokenSelectNetworkViewModelType {
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSendService() -> SendServiceType
    func getSOLAndRenBTCPrices() -> [String: Double]
    func getSelectedNetwork() -> SendToken.Network
    func selectRecipient(_ recipient: SendToken.Recipient?)
    func selectNetwork(_ network: SendToken.Network)
    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network)
}
