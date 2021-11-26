//
//  DApp.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2021.
//

import Foundation

struct DApp {
    let name: String
    let description: String
    let url: String
    
    static var fake: DApp {
        .init(name: "Fake DApp", description: "A fake dapp", url: "https://web.beardict.net/dapp/")
    }
}
