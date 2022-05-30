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

final class ___VARIABLE_scene___ViewModel: ViewModelType {
    // MARK: - Nested type

    struct Input {
        let navigatableScene = PublishRelay<___VARIABLE_scene___NavigatableScene>()
    }

    struct Output {
        let navigatableScene: Signal<___VARIABLE_scene___NavigatableScene>
    }

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
        )
    }
}
