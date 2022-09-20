//
//  CustomResponders.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2022.
//

import Foundation
import SolanaSwift

protocol ChangeLanguageResponder {
    func languageDidChange(to: LocalizedLanguage)
}

protocol ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: APIEndPoint)
}

protocol ChangeThemeResponder {
    func changeThemeTo(_ style: UIUserInterfaceStyle)
}

protocol LogoutResponder {
    func logout()
}
