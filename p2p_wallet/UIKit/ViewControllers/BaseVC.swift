//
//  BaseVC.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation
import UIKit

class BaseVC: BEViewController {
    deinit {
        print("\(String(describing: self)) deinited")
    }

    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
    }

    // TODO: - For re-overriding navigationController settings
    override func viewWillAppear(_: Bool) {}
}
