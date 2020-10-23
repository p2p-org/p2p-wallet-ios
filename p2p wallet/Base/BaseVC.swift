//
//  BaseVC.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation

class BaseVC: BEViewController {
    var padding: UIEdgeInsets { UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .white
    }
}
