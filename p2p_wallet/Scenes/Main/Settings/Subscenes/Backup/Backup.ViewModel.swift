//
//  Backup.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol BackupViewModelType {
    var navigationDriver: Driver<Backup.NavigatableScene?> {get}
}

extension Backup {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension Backup.ViewModel: BackupViewModelType {
    var navigationDriver: Driver<Backup.NavigatableScene?> {
        navigationSubject.asDriver()
    }
}
