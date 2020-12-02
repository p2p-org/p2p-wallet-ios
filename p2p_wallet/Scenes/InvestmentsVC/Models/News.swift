//
//  News.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation

struct News: ListItemType {
    static func placeholder(at index: Int) -> News {
        News(id: placeholderId(at: index), title: "News #\(index)", subtitle: nil, imageUrl: nil)
    }
    let id: String
    let title: String
    let subtitle: String?
    let imageUrl: String?
}
