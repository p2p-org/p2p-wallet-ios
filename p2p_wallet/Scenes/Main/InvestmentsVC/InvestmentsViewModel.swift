//
//  InvestmentsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import UIKit
import RxSwift
import RxCocoa

// enum InvestmentsNavigatableScene {
//    case detail
// }

class InvestmentsViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let newsViewModel: NewsViewModel
    let defisViewModel: DefisViewModel
    
    // MARK: - Subjects
//    let navigationSubject = PublishSubject<InvestmentsNavigatableScene>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(
        newsViewModel: NewsViewModel,
        defisViewModel: DefisViewModel
    ) {
        self.newsViewModel = newsViewModel
        self.defisViewModel = defisViewModel
    }
    
    // MARK: - Actions
    @objc func reload() {
        newsViewModel.reload()
        defisViewModel.reload()
    }
//    @objc func showDetail() {
//        
//    }
}
