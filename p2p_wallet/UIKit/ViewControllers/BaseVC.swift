//
//  BaseVC.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation
import RxSwift

class BaseVC: BEViewController {
    let disposeBag = DisposeBag()
    
    /// Set true for hiding tabbar, leave it nil for
    var preferredTabBarHidden: Bool? {nil}
    
    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if preferredTabBarHidden == true {
            // hide tab bar
            NotificationCenter.default.post(name: .shouldHideTabBar, object: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if preferredTabBarHidden == true {
            // show tab bar
            NotificationCenter.default.post(name: .shouldHideTabBar, object: false)
        }
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
    }
}
