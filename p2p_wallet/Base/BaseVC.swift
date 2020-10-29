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
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
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
