//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import BEPureLayout

final class ___VARIABLE_scene___ViewController: BEScene {
    // MARK: - Dependencies

    private let viewModel: ___VARIABLE_scene___ViewModel

    // MARK: - Initializer

    init(viewModel: ___VARIABLE_scene___ViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    // MARK: - Methods

    override func build() -> UIView {
        ___VARIABLE_scene___RootView(viewModel: viewModel)
    }

    override func bind() {
        super.bind()
        viewModel.output.navigatableScene
            .emit(onNext: { [weak self] in self?.navigate(to: $0) })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    private func navigate(to scene: ___VARIABLE_scene___NavigatableScene?) {
        switch scene {
        case .detail:
            <#code#>
        case .none:
            break
        }
    }
}
