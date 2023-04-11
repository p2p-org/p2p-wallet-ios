//
//  File.swift
//  
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Foundation

public struct WormholeSendStatus: Codable, Equatable {
    public let status: WormholeStatus
    
    public let message: String
    
    public let userWallet: String
    
    public let recipient: String
    
    public let amount: TokenAmount
    
    public let fees: SendFees
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case userWallet = "user_wallet"
        case recipient
        case amount
        case fees
    }
}
