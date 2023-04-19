//
//  RendableAccount+Mock.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 04.03.2023.
//

import Foundation

struct RendableMockAccount: RendableAccount {
    var id: String
    
    var icon: AccountIcon
    
    var wrapped: Bool
    
    var title: String
    
    var subtitle: String
    
    var detail: AccountDetail
    
    var extraAction: AccountExtraAction?
    
    var tags: AccountTags
}
