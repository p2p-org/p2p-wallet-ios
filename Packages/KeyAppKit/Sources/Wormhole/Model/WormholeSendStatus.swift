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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.status = try container.decode(WormholeStatus.self, forKey: .status)
        
        self.message = try container.decode(String.self, forKey: .message)
        self.userWallet = try container.decode(String.self, forKey: .userWallet)
        self.recipient = try container.decode(String.self, forKey: .recipient)
        self.amount = try container.decode(TokenAmount.self, forKey: .amount)
        self.fees = try container.decode(SendFees.self, forKey: .fees)
    }
}
