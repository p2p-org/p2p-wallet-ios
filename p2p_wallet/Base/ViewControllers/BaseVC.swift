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
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
        adjustContentInsetToFitTabBar()
    }
    
    func adjustContentInsetToFitTabBar() {
        scrollViewAvoidingTabBar?.contentInset = scrollViewAvoidingTabBar?.contentInset.modifying(dBottom: 20) ?? .zero
    }
    
    func forceResizeModal() {
        preferredContentSize.height += 1
    }
    
    #if DEBUG //1
    @objc func injected() { //2
        for subview in self.view.subviews {
            subview.removeFromSuperview()
        }
        
        viewDidLoad() //4
    }
    #endif
}
