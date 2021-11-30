//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxCocoa

extension SendToken.ChooseRecipientAndNetwork {
    struct SelectAddress {
        enum NavigatableScene {
            case detail
        }
        
        enum AddressType: Equatable {
            case raw(address: String, hasFunds: Bool)
            case resolvedName(name: String, address: String)
        }
        
        enum InputState: Equatable {
            case entering(String?)
            case selected(AddressType)
            
            var isEntering: Bool {
                switch self {
                case .entering:
                    return true
                default:
                    return false
                }
            }
        }
    }
}
