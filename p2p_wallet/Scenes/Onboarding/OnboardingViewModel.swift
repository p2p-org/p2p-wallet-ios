//
//  OnboardingViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa

enum OnboardingNavigatableScene: Int {
    case pincode = 0
    case biometry
    case notification
    
    var next: Self? {
        Self(rawValue: rawValue + 1)
    }
}

struct OnboardingViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let bag = DisposeBag()
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<OnboardingNavigatableScene>()
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializer
    init() {
        bind()
    }
    
    // MARK: - Binding
    func bind() {
        
    }
    
    // MARK: - Actions
//    @objc func showDetail() {
//        
//    }
}
