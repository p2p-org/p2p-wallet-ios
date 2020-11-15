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
        BalancesVM.ofCurrentUser.data.accept(0)
        BalancesVM.ofCurrentUser.state.accept(.loading)
        AppDelegate.shared.reloadRootVC()
    }
}
