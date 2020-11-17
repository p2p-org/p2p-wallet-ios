//
//  ProfileVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation

class ProfileVC: BaseVC {
    lazy var logoutButton = UIButton(backgroundColor: .textWhite, cornerRadius: 10, label: "Logout", textColor: .textBlack, contentInsets: UIEdgeInsets(x: 16, y: 10))
        .onTap(self, action: #selector(buttonLogoutButton))
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        view.addSubview(logoutButton)
        logoutButton.autoCenterInSuperview()
    }
    
    @objc func buttonLogoutButton() {
        KeychainStorage.shared.clear()
        SolBalanceVM.ofCurrentUser.data = Price(from: "SOL", to: "USDT", value: 0, change24h: nil)
        SolBalanceVM.ofCurrentUser.state.accept(.initializing)
        AppDelegate.shared.reloadRootVC()
    }
}
