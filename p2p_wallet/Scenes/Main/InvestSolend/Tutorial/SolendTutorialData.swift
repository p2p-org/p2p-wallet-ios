//
//  SolendTutorialData.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2022.
//

import Foundation

struct SolendTutorialContentData: Identifiable {
    let id = UUID().uuidString
    let image: UIImage
    let title: String
    let subtitle: String
}
