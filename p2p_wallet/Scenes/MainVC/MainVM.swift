//
//  MainVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation
import RxSwift

class MainVM: ListViewModel<MainVCItem> {
    let walletsVM = WalletsVM.ofCurrentUser
    
    override func reload() {
        walletsVM.reload()
    }
    
    override var dataDidChange: Observable<Void> {
        walletsVM.dataDidChange
    }
}
