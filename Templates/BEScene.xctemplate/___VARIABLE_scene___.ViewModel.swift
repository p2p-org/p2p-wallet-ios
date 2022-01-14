//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import Foundation
import RxSwift
import RxCocoa

protocol ___VARIABLE_scene___ViewModelType {
    var navigationDriver: Driver<___VARIABLE_scene___.NavigatableScene?> {get}
    func navigate(to scene: ___VARIABLE_scene___.NavigatableScene)
}

extension ___VARIABLE_scene___ {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Initializers
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension ___VARIABLE_scene___.ViewModel: ___VARIABLE_scene___ViewModelType {
    var navigationDriver: Driver<___VARIABLE_scene___.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: ___VARIABLE_scene___.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
