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

extension ___VARIABLE_scene___ViewModel: ViewModelType {
    
    // MARK: - Nested type

    struct Input {
        let navigatableScene = PublishRelay<___VARIABLE_scene___NavigatableScene>()
//        let clicked = PublishRelay<Void>()
    }

    struct Output {
        let navigatableScene: Signal<___VARIABLE_scene___NavigatableScene>
//        let text: Driver<String?>
    }
}

final class ___VARIABLE_scene___ViewModel {
    
    // MARK: - Dependencies

//        @Injected private var service: Service

    // MARK: - Properties

    let input: Input
    let output: Output

    // MARK: - Initializers

    init() {
        input = Input()
        output = Output(
            navigatableScene: input.navigatableScene
                .asSignal()
//            text: service.text.asDriver()
        )
    }
}
