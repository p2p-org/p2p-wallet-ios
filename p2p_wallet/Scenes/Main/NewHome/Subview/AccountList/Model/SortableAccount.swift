//
//  SortableAccount.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 18/07/23.
//

import BigDecimal

protocol SortableAccount: RenderableAccount {
    var sortingKey: BigDecimal? { get }
}

extension SortableAccount {
    var sortingKey: BigDecimal? { nil }
}
