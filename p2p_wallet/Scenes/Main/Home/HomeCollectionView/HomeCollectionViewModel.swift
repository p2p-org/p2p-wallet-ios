//
//  HomeCollectionViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import RxSwift

class HomeCollectionViewModel: ListViewModel<HomeItem> {
    // MARK: - Properties
    let walletsVM: WalletsVM
    
    init(walletsVM: WalletsVM) {
        self.walletsVM = walletsVM
        super.init()
    }
    
    // MARK: - Methods
    override func reload() {
        walletsVM.reload()
    }
    
    override var dataDidChange: Observable<Void> {
        walletsVM.dataDidChange
    }
}
