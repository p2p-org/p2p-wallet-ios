//
//  ReceiveTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

class ReceiveTokenVC: WLBottomSheet {
    override func setUp() {
        super.setUp()
        title = L10n.receiveToken
        let qrWrapperView = UIView(height: 315, backgroundColor: .buttonSub, cornerRadius: 15)
        stackView.addArrangedSubview(qrWrapperView)
    }
}
