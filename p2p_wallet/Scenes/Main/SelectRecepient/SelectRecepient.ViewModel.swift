//
//  SelectRecepient.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.10.2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SelectRecepientViewModelType {
    var navigationDriver: Driver<SelectRecepient.NavigatableScene?> {get}
    func showDetail()
}

extension SelectRecepient {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension SelectRecepient.ViewModel: SelectRecepientViewModelType {
    var navigationDriver: Driver<SelectRecepient.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func showDetail() {
        navigationSubject.accept(.detail)
    }
}
