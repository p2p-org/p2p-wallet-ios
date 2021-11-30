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
        
        enum InputState: Equatable {
            case entering(String?)
            case selected(SendToken.Recipient)
            
            var isEntering: Bool {
                switch self {
                case .entering:
                    return true
                default:
                    return false
                }
            }
            
            var recipient: SendToken.Recipient? {
                switch self {
                case .selected(let recipient):
                    return recipient
                default:
                    return nil
                }
            }
        }
    }
}
