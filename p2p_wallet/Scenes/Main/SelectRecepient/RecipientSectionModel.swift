//
//  RecipientSectionModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.10.2021.
//

import RxDataSources

struct RecipientsSection {
    var header: String
    var items: [Recipient]
}

extension RecipientsSection: SectionModelType {
    typealias Item = Recipient

    init(original: RecipientsSection, items: [Item]) {
        self = original
        self.items = items
    }
}
