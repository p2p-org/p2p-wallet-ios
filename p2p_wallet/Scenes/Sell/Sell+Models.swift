//
//  SellSubscene.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2022.
//

import Foundation

enum SellNavigation {
    case webPage(url: URL)
}

enum SellError: Error {
    case invalidURL
}
