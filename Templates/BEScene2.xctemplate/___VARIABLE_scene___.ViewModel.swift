//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift

extension ___VARIABLE_scene___ {
    final class ViewModel: ViewModelType {
        // MARK: - Nested type

        struct Input {
            let navigate: AnyObserver<NavigatableScene?>
        }

        struct Output {
            let navigatableScene: Signal<NavigatableScene?>
        }

        // MARK: - Dependencies

//        private let service: Service = Resolver.resolve()

        // MARK: - Properties

        let input: Input
        let output: Output

        // MARK: - Subjects

        private let navigatableSceneSubject = PublishSubject<NavigatableScene?>()
//        private let stringSubject = BehaviorRelay<String?>(value: nil)

        // MARK: - Initializers

        init() {
            input = Input(
                navigate: navigatableSceneSubject.asObserver()
            )
            output = Output(
                navigatableScene: navigatableSceneSubject
                    .asSignal(onErrorJustReturn: nil)
            )
        }
    }
}
