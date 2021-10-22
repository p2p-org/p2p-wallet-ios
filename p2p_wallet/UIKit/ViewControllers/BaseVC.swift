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
    var scrollViewAvoidingTabBar: UIScrollView? {nil}
    
    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
        adjustContentInsetToFitTabBar()
    }
    
    func adjustContentInsetToFitTabBar() {
        scrollViewAvoidingTabBar?.contentInset = scrollViewAvoidingTabBar?.contentInset.modifying(dBottom: 20) ?? .zero
    }
    
    func forceResizeModal() {
        view.layoutIfNeeded()
        preferredContentSize.height += 1
    }
}
