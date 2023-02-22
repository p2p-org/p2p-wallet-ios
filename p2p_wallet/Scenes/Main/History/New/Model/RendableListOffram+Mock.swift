//
//  RendableListOffram+Mock.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation

struct MockRendableListOfframItem: RendableListOfframItem {
    var id: String
    
    var date: Date = Date()
    
    var status: RendableListOfframStatus
    
    var title: String
    
    var subtitle: String
    
    var detail: String
    
    var onTap: (() -> Void)? = nil
}

extension MockRendableListOfframItem {
    static func error() -> Self {
        .init(id: UUID().uuidString, status: .error, title: L10n.youVeNotSent, subtitle: "SOL to Moonpay", detail: "$190.91")
    }
    
    static func waiting() -> Self {
        .init(id: UUID().uuidString, status: .ready, title: L10n.youNeedToSendSOL("65"), subtitle: "To ...Fv2P", detail: "$190.91")
    }
    
    static func processing() -> Self {
        .init(id: UUID().uuidString, status: .ready, title: L10n.processing, subtitle: L10n.toYourBankAccount, detail: "$190.91")
    }
    
    static func done() -> Self {
        .init(id: UUID().uuidString, status: .ready, title: L10n.fundsWereSent, subtitle: L10n.toYourBankAccount, detail: "$190.91")
    }
}
