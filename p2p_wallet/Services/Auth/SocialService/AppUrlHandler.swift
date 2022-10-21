//
//  AppUrlHandler.swift
//  p2p_wallet
//
//  Created by Ivan on 20.07.2022.
//

import UIKit

protocol AppUrlHandler {
    func handle(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool
}
